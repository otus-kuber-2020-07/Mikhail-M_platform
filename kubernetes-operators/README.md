Что сделал:
- Подготовил скрипт mysql-operator.py и Docker образ. (скрипт демонстрирует возможности работы с kuber через api, в частности мы описываем, что нужно сделать при создании или удалении объекта определенного типа -- бэкап и восстановление из бэкапа)


- Описал CRD с валидацией схемы(запрещаем поля) и описал Deployment для оператора


Шаги к выполнению:

Создаем все ресурсы
~~~
kubectl apply -f kubernetes-operators/deploy/crd.yml
kubectl apply -f kubernetes-operators/deploy/service-account.yml
kubectl apply -f kubernetes-operators/deploy/role.yml
kubectl apply -f kubernetes-operators/deploy/role-binding.yml
kubectl apply -f kubernetes-operators/deploy/deploy-operator.yml
kubectl apply -f kubernetes-operators/deploy/cr.yml
~~~

Заполняем базку
~~~
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}" | xargs)
kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );" otus-database
~~~


Смотрим базу
~~~
kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
~~~

Удаляем ресурс, должен выполниться бэкап
~~~
kubectl delete mysqls.otus.homework mysql-instance
kubectl get jobs.batch # можно  глянуть на джобку 
# backup-mysql-instance-job    1/1           2s         31s
~~~
Всстанавливаем ресурс
~~~
kubectl apply -f kubernetes-operators/deploy/cr.yml
kubectl get jobs.batch
~~~


