# import os
# import json
# import airflow
# from airflow import DAG
# from airflow.operators.bash import BashOperator
# from airflow.operators.python_operator import PythonOperator
# from datetime import timedelta

# from azure.cosmos.cosmos_client import CosmosClient
# from azure.cosmos.errors import HTTPFailure

# # タスクで呼び出す関数
# # 本来は read_cosmos_items と upsert_cosmos で共通利用する項目は別で定義しますが今回は割愛
# def read_cosmos_items():
#     # Define additional variables
#     database_name = 'Sample'
#     container_name = 'jcdug20210214'
#     os.environ['COSMOS_ACCOUNT_NAME'] = ''
#     os.environ['COSMOS_Secret'] = ''

#     # Connect to Azure Cosmos DB
#     cosmos_account = os.environ['COSMOS_ACCOUNT_NAME']
#     cosmos_key = os.environ['COSMOS_Secret']
#     url = f"https://{cosmos_account}.documents.azure.com:443/"
#     client = CosmosClient(url, {'masterKey': cosmos_key})
#     print(f"[{cosmos_account}] Connected successfully to Azure Cosmos DB account.")

#     # Query container
#     try:
#         result_iterable = client.QueryItems(
#             f"dbs/{database_name}/colls/{container_name}",
#             {
#                 "query": "SELECT * FROM c WHERE c.category='enemy'"
#             },
#         )
#         return list(result_iterable)

#     except HTTPFailure:
#         return None

# def upsert_cosmos():
#     # Define additional variables
#     database_name = 'Sample'
#     container_name = 'jcdug20210214'
#     os.environ['COSMOS_ACCOUNT_NAME'] = ''
#     os.environ['COSMOS_Secret'] = ''

#     # Connect to Azure Cosmos DB
#     cosmos_account = os.environ['COSMOS_ACCOUNT_NAME']
#     cosmos_key = os.environ['COSMOS_Secret']
#     url = f"https://{cosmos_account}.documents.azure.com:443/"
#     client = CosmosClient(url, {'masterKey': cosmos_key})
#     print(f"[{cosmos_account}] Connected successfully to Azure Cosmos DB account.")

#     try:
#         created_document = client.CreateItem(
#             f"dbs/{database_name}/colls/{container_name}",
#             {'id': '5', 'category': 'demon-slayer-corps', 'name': '冨岡 義勇', 'description': '鬼殺隊の隊士で、炭治郎を鬼殺隊へと導く。', 'isAlive': True},
#         )
#         return created_document

#     except HTTPFailure:
#         return None

# # DAG ファイルの既定値
# args = {
#     'owner': 'Pramod', # DAG の所有者  
#     'start_date': airflow.utils.dates.days_ago(3), # タスクの開始日時
#     'depends_on_past': False,
#     'email': ['airflow@example.com'], # 障害発生時などにメール送信を行う宛先
#     'email_on_failure': False, # タスク失敗時にメールを送信するか否か
#     'email_on_retry': False, # タスクのリトライが発生した際にメールを送信するか否か
#     'retries': 1, # タスク失敗時のリトライ回数
#     'retry_delay': timedelta(minutes=5), # タスクが失敗してからリトライが行われるまでの待ち時間
#     # 'queue': 'bash_queue',
#     # 'pool': 'backfill',
#     # 'priority_weight': 10,
#     # 'end_date': datetime(2021, 12, 31), # タスクの終了日時
#     # 'wait_for_downstream': False,
#     # 'dag': dag,
#     # 'sla': timedelta(hours=2),
#     # 'execution_timeout': timedelta(seconds=300),
#     # 'on_failure_callback': some_function,
#     # 'on_success_callback': some_other_function,
#     # 'on_retry_callback': another_function,
#     # 'sla_miss_callback': yet_another_function,
#     # 'trigger_rule': 'all_success'
# }

# # DAG 情報作成
# dag = DAG(
#     'sample_cosmos_dag', # DAG の名前
#     default_args=args, # DAG のデフォルト引数
#     description='Azure Cosmos DB 操作テスト', # DAG の説明
#     schedule_interval=timedelta(days=1), # タスクの実行間隔
#     # start_date=airflow.utils.dates.days_ago(3), # ここでも指定可能
#     tags=['example','cosmosdb']
# )

# # タスク定義
# t1 = PythonOperator(
#     task_id='read_cosmos_items',
#     python_callable=read_cosmos_items,
#     dag=dag,
# )

# t2 = BashOperator(
#     task_id='sleep',
#     depends_on_past=False,
#     bash_command='sleep 5',
#     retries=3,
#     dag=dag,
# )

# templated_command = """
# {% for i in range(5) %}
#     echo "{{ ds }}"
#     echo "{{ macros.ds_add(ds, 7)}}"
#     echo "{{ params.my_param }}"
# {% endfor %}
# """

# t3 = BashOperator(
#     task_id='templated',
#     depends_on_past=False,
#     bash_command=templated_command,
#     params={'my_param': 'Parameter I passed in'},
#     dag=dag,
# )

# t4 = PythonOperator(
#     task_id='upsert_cosmos',
#     python_callable=upsert_cosmos,
#     dag=dag,
# )

# t1 >> [t2, t3] >> t4
