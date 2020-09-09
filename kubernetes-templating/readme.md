- установил nginx-ingress
~~~
kubectl create ns nginx-ingress

helm upgrade --install nginx-ingress stable/nginx-ingress --wait \
 --namespace=nginx-ingress \
 --version=1.41.3
 ~~~
 
 - установил cert-manager
 ~~~
 helm repo add jetstack https://charts.jetstack.io
 
 kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.16.1/cert-manager.crds.yaml
 
 helm upgrade --install cert-manager jetstack/cert-manager --wait \
 --namespace=cert-manager \
 --version=0.16.1
 ~~~
 
 - основываясь на документации, добавил ClusterIssuer


ref: https://cert-manager.io/docs/configuration/acme/ , https://cert-manager.io/docs/tutorials/acme/ingress/ 
 ~~~
 kubectl apply -f kubernetes-templating/cert-manager/cluster-issuer-prod.yaml
 kubectl apply -f kubernetes-templating/cert-manager/cluster-issuer-staging.yaml
 ~~~
 

- установил chartmuseum, c опциями автовыписывания сертификата и корректным hostname(посмотрел его через <b>kubectl get service --namespace=nginx-ingress</b>), прошел по нужному адресу и увидел, что **Connection is secure**

~~~
kubectl create ns chartmuseum

helm upgrade --install chartmuseum stable/chartmuseum --wait \
 --namespace=chartmuseum \
 --version=2.13.2 \
 -f kubernetes-templating/chartmuseum/values.yaml
 ~~~
 
 - chartmuseum задание со звездочкой [todo]
 
 - установил harbor, зашел на него
 
 ~~~
 kubectl create ns harbor
 
 helm upgrade --install harbor harbor/harbor --wait \ 
  --namespace=harbor \
  --version=1.1.2 \ 
  -f kubernetes-templating/harbor/values.yaml
 ~~~
 
 - написал helmfile для одновременной установки  nginx-ingress, cert-manager и harbor
 ~~~
 helm plugin install https://github.com/databus23/helm-diff # - а то не работало
 cd kubernetes-templating/helmfile
 helmfile sync
 ~~~
 
 - запустил hipster-shop, через kube-forwarder пробросил порты и посмотрел фронт
 ~~~
  helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
 ~~~
 - вынес фронт из hipster-shop, добился того, что он поднялся
 ~~~
 helm upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop
 ~~~
 - пошаблонизировал фронт и поиграл с этим, добавил его в зависимости к hipster-shop
 - [todo] установить redis
 - [todo] работа с секретами в helm
 
 - установил плагин для пуша и запушил
 ~~~
 helm plugin install https://github.com/chartmuseum/helm-push.git
 sh repo.sh
 ~~~