# Aplicación FreshBox — catálogo de productos

CRUD de productos orgánicos repartido en cinco contenedores Docker: un frontend que además actúa como *reverse proxy* y cuatro microservicios Node.js, uno por operación. Es la carga que corre sobre la capa App de la arquitectura ([`../infra/`](../infra/)).

## Microservicios

| Contenedor | Puerto | Ruta | Método |
|---|---|---|---|
| `frontend` | 80 | `/` | — (sirve la interfaz y enruta `/api/*`) |
| `get-products` | 3001 | `/api/products` | GET |
| `create-product` | 3002 | `/api/products` | POST |
| `update-product` | 3003 | `/api/products/:id` | PUT |
| `delete-product` | 3004 | `/api/products/:id` | DELETE |

El navegador **nunca** habla con los puertos 3001-3004: llama siempre a la ruta relativa `/api/products` sobre el puerto 80, y el nginx del contenedor `frontend` decide el backend según el método HTTP. Esto es lo que permite que la aplicación funcione detrás del Application Load Balancer, que solo expone 80/443 y no alcanza las instancias privadas por otros puertos.

```nginx
location /api/products {
    if ($request_method = GET)  { proxy_pass http://get-products:3001; }
    if ($request_method = POST) { proxy_pass http://create-product:3002; }
}
location ~ ^/api/products/(\d+)$ {
    if ($request_method = PUT)    { proxy_pass http://update-product:3003; }
    if ($request_method = DELETE) { proxy_pass http://delete-product:3004; }
}
```

nginx resuelve `get-products`, `create-product`, etc. por DNS interno de la red Docker. En AWS los contenedores se lanzan con `--network-alias` para que respondan por esos nombres cortos, no solo por el nombre del contenedor.

## Estructura

```
codigo/
├── docker-compose.yml          Entorno local completo (incluye MySQL)
├── init.sql                    Base freshbox, usuario, tabla productos y 5 registros
├── microservicioFrontend/
│   ├── Dockerfile              nginx alpine
│   ├── nginx.conf              Enrutamiento por método HTTP
│   ├── index.html · css/ · js/ Interfaz del catálogo
├── microserviciosBackend/
│   ├── get-products/           Dockerfile · package.json · index.js
│   ├── create-product/
│   ├── update-product/
│   └── delete-product/
└── scripts/
    ├── ecr-push.sh             Crear repositorios y publicar las 5 imágenes
    ├── deploy-containers.sh    Levantar los 5 contenedores en una EC2
    └── user-data-ec2.sh        Instalación de Docker en el arranque
```

## Configuración

Cada microservicio se configura por variables de entorno:

| Variable | Local (`docker compose`) | En AWS |
|---|---|---|
| `DB_HOST` | `db` | IP privada de la EC2 de datos, inyectada por CloudFormation |
| `DB_USER` | `alumno` | `alumno` |
| `DB_PASS` | `alumno123` | parámetro `DBPassword` del stack de cómputo |
| `DB_NAME` | `freshbox` | `freshbox` |
| `DB_PORT` | `3306` | `3306` |

> Las credenciales son de laboratorio, no productivas. Gestionarlas en AWS Secrets Manager o SSM Parameter Store `SecureString` está declarado como brecha de seguridad en el informe (punto 1.3).

## Prueba local

```bash
cd codigo
docker compose up -d --build
docker compose ps
```

- Interfaz: <http://localhost:8080>
- API a través del frontend: <http://localhost:8080/api/products>

Los cuatro microservicios quedan además publicados directamente en los puertos 3001-3004 para depuración, pero conviene probar por el 8080, que es el camino real en producción.

```bash
curl http://localhost:8080/api/products
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Quinoa organica 500g","descripcion":"Quinoa premium","precio":4990,"stock":80,"categoria":"Granos"}'
curl -X PUT http://localhost:8080/api/products/6 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Quinoa organica 1kg","descripcion":"Quinoa premium","precio":8990,"stock":50,"categoria":"Granos"}'
curl -X DELETE http://localhost:8080/api/products/6
```

Para detener y borrar el volumen de la base: `docker compose down -v`.

## Publicar las imágenes en Amazon ECR

Las instancias de la capa App son `t4g.small` (AWS Graviton), así que las imágenes deben construirse para **`linux/arm64`**. Si se construyen desde AWS CloudShell —que corre en `amd64`— hay que registrar los emuladores QEMU y usar un builder con driver `docker-container`; de lo contrario `npm install` falla con `exec format error`.

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name freshbox-builder --driver docker-container --use
docker buildx inspect --bootstrap

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text); REGION="us-east-1"
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

for R in freshbox-frontend freshbox-get-products freshbox-create-product \
         freshbox-update-product freshbox-delete-product; do
  aws ecr create-repository --repository-name $R --region $REGION 2>/dev/null || echo "$R ya existe"
done

docker buildx build --platform linux/arm64 --load -t freshbox-frontend ./microservicioFrontend
docker tag freshbox-frontend $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-frontend:latest

for S in get-products create-product update-product delete-product; do
  docker buildx build --platform linux/arm64 --load -t freshbox-$S ./microserviciosBackend/$S
  docker tag freshbox-$S $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-$S:latest
  docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/freshbox-$S:latest
done
```

El `--load` es necesario para que la imagen quede en el daemon local y pueda etiquetarse y publicarse.

## Nota sobre los scripts

Los tres archivos de [`scripts/`](scripts/) son la versión manual de referencia, previa a la infraestructura como código. En el despliegue final **no se ejecutan a mano**: su lógica está incorporada en el `UserData` del Launch Template de [`../infra/03-compute.yaml`](../infra/03-compute.yaml), que instala Docker, autentica contra ECR y levanta los 5 contenedores apuntando a la IP privada de la base de datos, sin intervención humana. Se conservan como documentación del procedimiento equivalente paso a paso; `deploy-containers.sh` mantiene un `DB_HOST` de ejemplo que debe reemplazarse si se usa de forma manual.

## Defectos corregidos antes de desplegar

Dos problemas del código original habrían impedido que el CRUD funcionara detrás del balanceador, y ninguno se manifestaba en pruebas locales:

1. **El frontend llamaba a puertos fijos** (`:3001` a `:3004`) en lugar de rutas relativas. En `docker compose` funcionaba porque los puertos están publicados en el host; en AWS el navegador nunca habría alcanzado instancias en subred privada. Corregido usando `/api/products` con nginx como *reverse proxy* interno.
2. **Los nombres de contenedor no coincidían con los hostnames que resuelve nginx** (`freshbox-get-products` frente a `get-products`). Corregido agregando `--network-alias` a cada `docker run`.

El análisis completo de ambos, con su impacto por pilar del Well-Architected Framework, está en [`../notas/bitacora.md`](../notas/bitacora.md).

## Datos iniciales

`init.sql` crea la base `freshbox`, el usuario de aplicación y la tabla `productos` con cinco registros: manzana orgánica 1 kg, lechuga hidropónica, granola artesanal 500 g, jugo natural de naranja 1 L y mix de frutos secos 250 g. El mismo esquema y los mismos datos se aprovisionan en AWS desde el `UserData` de la instancia de datos.

---

2026 · Base de la aplicación entregada por la asignatura — Diseñador: Ignacio A. Pastenet M.
