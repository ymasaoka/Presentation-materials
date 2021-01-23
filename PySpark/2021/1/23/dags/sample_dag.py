from datetime import timedelta

import airflow
from airflow import DAG
from airflow.operators.bash import BashOperator



args = {
    'owner': 'Pramod', # DAG の所有者  
    'start_date': airflow.utils.dates.days_ago(3), # タスクの開始日時
    'depends_on_past': False,
    'email': ['airflow@example.com'], # 障害発生時などにメール送信を行う宛先
    'email_on_failure': False, # タスク失敗時にメールを送信するか否か
    'email_on_retry': False, # タスクのリトライが発生した際にメールを送信するか否か
    'retries': 1, # タスク失敗時のリトライ回数
    'retry_delay': timedelta(minutes=5), # タスクが失敗してからリトライが行われるまでの待ち時間
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2021, 12, 31), # タスクの終了日時
    # 'wait_for_downstream': False,
    # 'dag': dag,
    # 'sla': timedelta(hours=2),
    # 'execution_timeout': timedelta(seconds=300),
    # 'on_failure_callback': some_function,
    # 'on_success_callback': some_other_function,
    # 'on_retry_callback': another_function,
    # 'sla_miss_callback': yet_another_function,
    # 'trigger_rule': 'all_success'
}


dag = DAG(
    'sample_airflow_dag', # DAG の名前
    default_args=args, # DAG のデフォルト引数
    description='簡単な DAG テスト', # DAG の説明
    schedule_interval=timedelta(days=1), # タスクの実行間隔
    # start_date=airflow.utils.dates.days_ago(3), # ここでも指定可能
    tags=['example']
)


t1 = BashOperator(
    task_id='print_date',
    bash_command='date',
    dag=dag,
)

t2 = BashOperator(
    task_id='sleep',
    depends_on_past=False,
    bash_command='sleep 5',
    retries=3,
    dag=dag,
)
dag.doc_md = __doc__

t1.doc_md = """\
#### Task Documentation
You can document your task using the attributes `doc_md` (markdown),
`doc` (plain text), `doc_rst`, `doc_json`, `doc_yaml` which gets
rendered in the UI's Task Instance Details page.
![img](http://montcs.bloomu.edu/~bobmon/Semesters/2012-01/491/import%20soul.png)
"""
templated_command = """
{% for i in range(5) %}
    echo "{{ ds }}"
    echo "{{ macros.ds_add(ds, 7)}}"
    echo "{{ params.my_param }}"
{% endfor %}
"""

t3 = BashOperator(
    task_id='templated',
    depends_on_past=False,
    bash_command=templated_command,
    params={'my_param': 'Parameter I passed in'},
    dag=dag,
)



t1 >> [t2, t3]

