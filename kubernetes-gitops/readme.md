Подготовительная часть:

- настроил CI в гитлабе для образов
  - .gitlab.ci.yaml
  - ./ci/pipelines/
  
- установим istio plugin
~~~
gcloud beta container clusters update cluster-1    
    --update-addons=Istio=ENABLED 
    --istio-config=auth=MTLS_PERMISSIVE
    --zone us-central1-c
    --project clever-gadget-288419
~~~
  
- устанавливаем парочку crd
~~~
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml

~~~
- установил crd для HELM RELEASE 
~~~
 kubectl apply -f https://raw.githubusercontent.com/stefanprodan/appmesh-dev/master/flux/flux-helm-release-crd.yaml
~~~
- установил FLUX
~~~
 kubectl create ns flux
 helm repo add fluxcd https://charts.fluxcd.io
 helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
~~~

- ключик кладем в гитлаб
~~~
fluxctl identity --k8s-fwd-ns flux > ssh_key 

~~~
- установил helm-operator
~~~
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux
~~~

Проверка: 

- сделал пуш с namespace для microservices-demo, появился ресурс в кластере, в логах flux pod тоже есть


HelmRelease:

- чек, что эта штука есть
~~~
kubectl get helmrelease -n microservices-demo
helm list -n microservices-demo
~~~


~~~
helm history frontend -n microservices-demo
> 
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION     
1               Tue Oct  6 14:56:34 2020        superseded      frontend-0.21.0 1.16.0          Install complete
2               Tue Oct  6 16:01:48 2020        deployed        frontend-0.21.0 1.16.0          Upgrade complete
~~~


Последнее, что нужно сделать -- это сменить название frontend -> frontend-hipster и посмотреть что будет
~~~
wh0106259:microservices-demo mikhail.maryufich$ helm history frontend -n microservices-demo
REVISION        UPDATED                         STATUS          CHART                   APP VERSION     DESCRIPTION     
1               Tue Oct  6 14:56:34 2020        superseded      frontend-0.21.0         1.16.0          Install complete
2               Tue Oct  6 16:01:48 2020        superseded      frontend-0.21.0         1.16.0          Upgrade complete
3               Tue Oct  6 16:16:33 2020        deployed        frontend-hipster-0.21.0 1.16.0          Upgrade complete
~~~

Смотрим в логи
~~~
kubectl logs helm-operator-7c99864fb5-75pl9 -n flux  | grep frontend
>
ts=2020-10-06T19:35:34.425256735Z caller=helm.go:69 component=helm version=v3 info="Created a new Deployment called \"frontend-hipster\" in microservices-demo\n" targetNamespace=microservices-demo release=frontend
~~~

установил все остальные сервисы аналогично

~~~
wh0106259:microservices-demo mikhail.maryufich$ helm list -A
NAME                    NAMESPACE               REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
adservice               microservices-demo      2               2020-10-06 16:59:57.351926154 +0000 UTC deployed        adservice-0.5.0                 1.16.0     
cartservice             microservices-demo      2               2020-10-06 17:00:25.826670188 +0000 UTC deployed        cartservice-0.4.1               1.16.0     
checkoutservice         microservices-demo      1               2020-10-06 16:59:35.36031558 +0000 UTC  deployed        checkoutservice-0.4.0           1.16.0     
currencyservice         microservices-demo      2               2020-10-06 16:59:56.078585457 +0000 UTC deployed        currencyservice-0.4.0           1.16.0     
emailservice            microservices-demo      2               2020-10-06 17:00:02.959455078 +0000 UTC deployed        emailservice-0.4.0              1.16.0     
flux                    flux                    1               2020-10-06 10:06:19.223168 +0300 MSK    deployed        flux-1.5.0                      1.20.2     
frontend                microservices-demo      3               2020-10-06 16:16:33.408641838 +0000 UTC deployed        frontend-hipster-0.21.0         1.16.0     
grafana-load-dashboards microservices-demo      1               2020-10-06 16:59:39.562824714 +0000 UTC deployed        grafana-load-dashboards-0.0.3              
helm-operator           flux                    1               2020-10-06 10:07:49.947486 +0300 MSK    deployed        helm-operator-1.2.0             1.2.0      
loadgenerator           microservices-demo      2               2020-10-06 16:59:56.995919427 +0000 UTC deployed        loadgenerator-0.4.0             1.16.0     
paymentservice          microservices-demo      2               2020-10-06 17:00:02.611714549 +0000 UTC deployed        paymentservice-0.3.0            1.16.0     
productcatalogservice   microservices-demo      2               2020-10-06 17:00:03.451407286 +0000 UTC deployed        productcatalogservice-0.3.0     1.16.0     
recommendationservice   microservices-demo      2               2020-10-06 17:00:08.865279977 +0000 UTC deployed        recommendationservice-0.3.0     1.16.0     
shippingservice         microservices-demo      1               2020-10-06 16:59:50.001899825 +0000 UTC deployed        shippingservice-0.3.0           1.16.0     
~~~


### Canary deployments с Flagger и Istio
Установим istio

~~~
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.8 TARGET_ARCH=x86_64 sh -
kubectl create ns istio
cd istio-1.6.8/
istioctl install --set profile=demo
~~~

Пробуем через istioctl operator init 
~~~
istioctl operator init
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF

~~~
Установим Flagger 
~~~
helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml

helm upgrade --install flagger flagger/flagger \
--namespace=istio-system \
--set crd.create=false \
--set meshProvider=istio \
--set metricsServer=http://prometheus:9090
~~~

Добавляем флажок включить istio

Удаляем все поды, чтобы они возродились уже с istio и смотрим что есть istio
~~~
kubectl delete pods --all -n microservices-demo
kubectl describe pod -l app=frontend -n microservices-demo
~~~

Создаем frontend-gw, frontend-vs путем пуша

Смотрим EXTERNAL-IP
~~~
kubectl get svc istio-ingressgateway -n istio-system
~~~
Успешно инициализировал canary ресурс frontend :
~~~
kubectl get canary -n microservices-demo
~~~
    
Собираю новую версию фронта и жду пока произойдет канареечный деплой
~~~
 kubectl describe canary -n microservices-demo 
~~~

Доказательтство успешного релиза
~~~
wh0106259:microservices-demo mikhail.maryufich$ kubectl get canaries -n microservices-demo
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0        2020-10-18T20:30:21Z
~~~

Вывод describe
~~~
Name:         frontend
Namespace:    microservices-demo
Labels:       <none>
Annotations:  helm.fluxcd.io/antecedent: microservices-demo:helmrelease/frontend
API Version:  flagger.app/v1beta1
Kind:         Canary
Metadata:
  Creation Timestamp:  2020-10-18T20:11:49Z
  Generation:          2
  Resource Version:    22624
  Self Link:           /apis/flagger.app/v1beta1/namespaces/microservices-demo/canaries/frontend
  UID:                 04472c96-151e-4831-b75f-c4945c6075b3
Spec:
  Analysis:
    Interval:                 15s
    Max Weight:               50
    Step Weight:              20
    Step Weight Promotion:    100
    Threshold:                10
  Progress Deadline Seconds:  60
  Service:
    Gateways:
      frontend-gateway
    Hosts:
      *
    Port:         80
    Target Port:  8080
    Traffic Policy:
      Tls:
        Mode:     DISABLE
  Skip Analysis:  false
  Target Ref:
    API Version:  apps/v1
    Kind:         Deployment
    Name:         frontend
Status:
  Canary Weight:  0
  Conditions:
    Last Transition Time:  2020-10-18T20:30:21Z
    Last Update Time:      2020-10-18T20:30:21Z
    Message:               Canary analysis completed successfully, promotion finished.
    Reason:                Succeeded
    Status:                True
    Type:                  Promoted
  Failed Checks:           0
  Iterations:              0
  Last Applied Spec:       5855f9bb7d
  Last Promoted Spec:      5855f9bb7d
  Last Transition Time:    2020-10-18T20:30:21Z
  Phase:                   Succeeded
  Tracked Configs:
Events:
  Type     Reason  Age                    From     Message
  ----     ------  ----                   ----     -------
  Warning  Synced  26m                    flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less then desired generation
  Normal   Synced  25m (x2 over 26m)      flagger  all the metrics providers are available!
  Normal   Synced  25m                    flagger  Initialization done! frontend.microservices-demo
  Normal   Synced  15m                    flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  14m                    flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  14m                    flagger  Advance frontend.microservices-demo canary weight 2
  Normal   Synced  13m                    flagger  Advance frontend.microservices-demo canary weight 4
  Normal   Synced  12m                    flagger  Advance frontend.microservices-demo canary weight 6
  Normal   Synced  11m                    flagger  Advance frontend.microservices-demo canary weight 8
  Normal   Synced  10m                    flagger  Advance frontend.microservices-demo canary weight 10
  Warning  Synced  8m52s                  flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: 1 old replicas are pending termination
  Normal   Synced  8m21s (x6 over 9m46s)  flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo
~~~