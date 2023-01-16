# Datadog provider must be specified in each module which requires that provider
terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
      version = "3.10.0"

    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url =  "https://api.datadoghq.eu/"
}

#### Monitors ####

# App logs: Error status
resource "datadog_monitor" "monitor_log_alert_error_status" {
  type                = "log alert"
  name                = "App logs: Error status"
  message             = "{{#is_alert}}@slack-monitoring{{/is_alert}}\n\n\n{{log.attributes.data.severity}} in container {{log.attributes.data.resource.labels.container_name}}\n\n\nClick [here](https://app.datadoghq.eu/logs?query=%40data.severity%3A{{log.attributes.data.severity}}%20container_name%3A{{log.attributes.data.resource.labels.container_name}}%20project_id%3A${var.gcp-project-id}&cols=%40data.jsonPayload.message&index=&messageDisplay=inline&stream_sort=time%2Cdesc&viz=stream&from_ts={{eval \"last_triggered_at_epoch-4*60*1000\"}}&to_ts={{eval \"last_triggered_at_epoch+1*60*1000\"}}&live=false) for more information.\n\n"
  query               = "logs(\"@data.severity:ERROR container_name:container* project_id:${var.gcp-project-id}\").index(\"*\").rollup(\"cardinality\", \"@data.jsonPayload.message\").by(\"@data.jsonPayload.message\").last(\"5m\") > 0"

  monitor_thresholds {
    critical              = 0
  }
  
  groupby_simple_monitor  = false
  require_full_window     = false
  enable_logs_sample      = true

  new_group_delay         = 60

  include_tags            = false
  notify_audit            = false

  notify_no_data          = false
  renotify_interval       = 0   
}

# App logs: No Data Alert
resource "datadog_monitor" "monitor_log_alert_app_no_data" {
  type                = "log alert"
  name                = "App logs: No data"   
  message             = "@slack-monitoring\n\nNo data in the past 5 minutes on **{{pod_name.name}}**\n\n"
  query               = "logs(\"container_name:container* project_id:${var.gcp-project-id}\").index(\"*\").rollup(\"count\").last(\"5m\") < 1"

  monitor_thresholds {
    critical          = 1
  }
  
  enable_logs_sample      = true
  require_full_window     = false

  include_tags            = false
  notify_audit            = false

  notify_no_data          = true
  no_data_timeframe       = 5

}

# App logs: Warn status
resource "datadog_monitor" "monitor_log_alert_warn_status" {
  type                = "log alert"
  name                = "App logs: Warn status"  
  message             = "{{#is_alert}}@slack-monitoring{{/is_alert}}\n\n\n{{log.attributes.data.severity}} in container {{log.attributes.data.resource.labels.container_name}}\n\n\nClick [here](https://app.datadoghq.eu/logs?query=%40data.severity%3A{{log.attributes.data.severity}}%20container_name%3A{{log.attributes.data.resource.labels.container_name}}%20project_id%3A${var.gcp-project-id}&cols=%40data.jsonPayload.message&index=&messageDisplay=inline&stream_sort=time%2Cdesc&viz=stream&from_ts={{eval \"last_triggered_at_epoch-4*60*1000\"}}&to_ts={{eval \"last_triggered_at_epoch+1*60*1000\"}}&live=false) for more information.\n\n"
  query               = "logs(\"@data.severity:WARNING container_name:container* project_id:${var.gcp-project-id}\").index(\"*\").rollup(\"cardinality\", \"@data.jsonPayload.message\").by(\"@data.jsonPayload.message\").last(\"5m\") > 0"

  monitor_thresholds {
    critical              = 0
  }
  
  groupby_simple_monitor  = false
  require_full_window     = false
  enable_logs_sample      = true

  new_group_delay         = 60

  include_tags            = false
  notify_audit            = false

  notify_no_data          = false
  renotify_interval       = 0 
  
}

# Bucket storage: Total bytes anomaly
resource "datadog_monitor" "monitor_query_alert_bucket_storage_total_bytes" {
  type                = "query alert"
  name                = "Bucket storage: Total bytes anomaly"  
  message             = "@slack-monitoring : Storage Anomaly Alert\n\n\nCloud Storage bucket anomaly in the total sizes of all objects\n\nBucket: {{bucket_name.name}}\n\n"
  query               = "avg(last_1h):anomalies(avg:gcp.storage.storage.total_bytes {project_id:${var.gcp-project-id}} by {bucket_name}, 'agile', 2, direction='both', interval=20, alert_window='last_1m', seasonality='hourly', timezone='utc', count_default_zero='true') >= 0.2"
  monitor_thresholds {
    critical              = 0.2
    critical_recovery     = 0
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = false
  renotify_interval       = 0
 

  new_group_delay         = 60
  evaluation_delay        = 300
  escalation_message      = ""

  no_data_timeframe       = 10

  monitor_threshold_windows {
    trigger_window = "last_1m"
    recovery_window = "last_15m"    
  }
}

# Database CPU utilization
resource "datadog_monitor" "monitor_query_alert_database_cpu_utilization" {
  type                = "query alert"
  name                = "Database: CPU utilization"  
  message             = "@slack-monitoring : CPU Utilization Alert\n\n\nDatabase: {{database_id.name}}\n\nCPU utilization {{value}}/1\n\n"
  query               = "avg(last_1h):avg:gcp.cloudsql.database.cpu.utilization {project_id:${var.gcp-project-id}} by {database_id} > 0.9"
  monitor_thresholds {
    critical              = 0.9
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 120
  renotify_interval       = 0 

  new_group_delay         = 300
  evaluation_delay        = 300
  escalation_message      = ""
}

# Database: Disk utilization alert
resource "datadog_monitor" "monitor_query_alert_disk_utilization" {
  type                = "query alert"
  name                = "Database: Disk utilization"   
  message             = "@slack-monitoring : Disk Utilization Alert\n\n\nDatabase: {{database_id.name}}\n\nStorage disk utilization {{value}}/1.\n\n"
  query               = "avg(last_1h):avg:gcp.cloudsql.database.disk.utilization{project_id:${var.gcp-project-id}} by {database_id} >= 0.95"
  monitor_thresholds {
    critical          = 0.95
  }

  include_tags            = false
  notify_audit            = false

  notify_no_data          = false
  renotify_interval       = 0 

  new_group_delay         = 300
  evaluation_delay        = 300
}

# Database: Failed login alert
resource "datadog_monitor" "monitor_log_alert_failed_login" {
  type                = "log alert"
  name                = "Database: Failed login"    
  message             = "@slack-monitoring : Failed Login Alert\n\n\nDatabase: {{database_id.name}}\n\nLogin failed {{value}} times in the past 5 minutes\n\n{{log.message}}\n\n"
  query               = "logs(\"source:gcp.cloudsql.database project_id:${var.gcp-project-id}\").index(\"*\").rollup(\"count\").last(\"5m\") >= 10"

  monitor_thresholds {
    critical          = 10
  }

  include_tags            = false
  notify_audit            = false
  enable_logs_sample      = true

  notify_no_data          = false
}

# Database: Memory Utilization Alert
resource "datadog_monitor" "monitor_query_alert_database_memory_utilization" {
  type                = "query alert"
  name                = "Database: Memory utilization"
  message             = "@slack-monitoring : Memory Utilization Alert\n\n\nDatabase: {{database_id.name}}\n\nMemory utilization {{value}}/1.\n\n"
  query               = "avg(last_1h):avg:gcp.cloudsql.database.memory.utilization{project_id:${var.gcp-project-id}} by {database_id} >= 0.9"
  monitor_thresholds {
    critical          = 0.9
  }

  include_tags            = false
  notify_audit            = false

  notify_no_data          = false
  renotify_interval       = 0 

  new_group_delay         = 300
  evaluation_delay        = 300
  escalation_message      = ""
}

# Database: Online Status
resource "datadog_monitor" "monitor_query_alert_database_up" {
  type                = "query alert"
  name                = "Database: Online status"  
  message             = "@slack-monitoring : Online Status Alert\n\n\nDatabase: {{database_id.name}}\n\nHas not been online for the last 5 minutes.\n\n"
  query               = "avg(last_5m):avg:gcp.cloudsql.database.up{project_id:${var.gcp-project-id}} by {database_id} < 1"
  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  timeout_h               = 0

  notify_no_data          = false
  renotify_interval       = 0 

  new_group_delay         = 300
  evaluation_delay        = 300
  escalation_message      = ""
}

# Kubernetes: Datadog Agent status
resource "datadog_monitor" "monitor_query_alert_datadog_agent_running" {
  type                = "query alert"
  name                = "Kubernetes: Datadog Agent status"
  message             = "@slack-monitoring : Agent Status Alert\n\n\nDatadog Agent not running\n\n"
  query               = "avg(last_5m):avg:datadog.agent.running{project_id:${var.gcp-project-id}} < 1"
  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 10

  renotify_interval       = 0
}

# Kubernetes: Datadog Pod state
resource "datadog_monitor" "monitor_metric_alert_pod_state-datadog_agent" {
  type                = "metric alert"
  name                = "Kubernetes: Datadog Pod state"
  message             = "@slack-monitoring : Pod State Alert\n\n\nDatadog Agent has {{value}} Pods running\n\n"
  query               = "avg(last_5m):sum:kubernetes_state.pod.ready{pod_name:datadog*,condition:true, project:${var.gcp-project-id}} < 1"
  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 10
  
  renotify_interval       = 0
}

# Kubernetes: Instance CPU utilization
resource "datadog_monitor" "monitor_query_alert_instance_cpu_utilization" {
  type                = "query alert"
  name                = "Kubernetes: Instance CPU utilization"
  message             = "@slack-monitoring : CPU Utilization Alert\n\n\nKubernetes Instance: {{instance_name.name}}\n\nCPU utilization {{value}}/1\n\n"
  query               = "avg(last_1h):avg:gcp.gce.instance.cpu.utilization {cluster-name:cluster-stack, project_id:${var.gcp-project-id}} by {instance_name} > 0.9"
  monitor_thresholds {
    critical              = 0.9
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = false
  renotify_interval       = 0 

  new_group_delay         = 300
  evaluation_delay        = 300
  escalation_message      = ""
}

# Kubernetes: app-api Pod state
resource "datadog_monitor" "monitor_metric_alert_pod_state-app_api" {
  type                = "metric alert"
  name                = "Kubernetes: app-api Pod state" 
  message             = "@slack-monitoring : Pod State Alert\n\n\napp-api has {{value}} Pods running\n\n"
  query               = "avg(last_5m):sum:kubernetes_state.pod.ready{pod_name:app-api*,condition:true, project:${var.gcp-project-id}} < 1"

  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 10
  
  renotify_interval       = 0
}

# Kubernetes: app-extranet Pod state
resource "datadog_monitor" "monitor_metric_alert_pod_state-app_extranet" {
  type                = "metric alert"
  name                = "Kubernetes: app-extranet Pod state" 
  message             = "@slack-monitoring : Pod State Alert\n\n\napp-extranet has {{value}} Pods running\n\n"
  query               = "avg(last_5m):sum:kubernetes_state.pod.ready{pod_name:app-extranet*,condition:true, project:${var.gcp-project-id}} < 1"

  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 10
  
  renotify_interval       = 0
}

# Kubernetes: app-pdf Pod state
resource "datadog_monitor" "monitor_metric_alert_pod_state-app_pdf" {
  type                = "metric alert"
  name                = "Kubernetes: app-pdf Pod state" 
  message             = "@slack-monitoring : Pod State Alert\n\n\napp-pdf has {{value}} Pods running\n\n"
  query               = "avg(last_5m):sum:kubernetes_state.pod.ready{pod_name:app-pdf*,condition:true, project:${var.gcp-project-id}} < 1"

  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 10
  
  renotify_interval       = 0
}

# Kubernetes: app-queue-handler Pod state
resource "datadog_monitor" "monitor_metric_alert_pod_state-app_queue_handler" {
  type                = "metric alert"
  name                = "Kubernetes: app-queue-handler Pod state" 
  message             = "@slack-monitoring : Pod State Alert\n\n\napp-queue-handler has {{value}} Pods running\n\n"
  query               = "avg(last_5m):sum:kubernetes_state.pod.ready{pod_name:app-queue-handler*,condition:true, project:${var.gcp-project-id}} < 1"

  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 10
  
  renotify_interval       = 0
}

# Kubernetes: app-web Pod state
resource "datadog_monitor" "monitor_metric_alert_pod_state-app_web" {
  type                = "metric alert"
  name                = "Kubernetes: app-web Pod state" 
  message             = "@slack-monitoring : Pod State Alert\n\n\napp-web has {{value}} Pods running\n\n"
  query               = "avg(last_5m):sum:kubernetes_state.pod.ready{pod_name:app-web*,condition:true, project:${var.gcp-project-id}} < 1"

  monitor_thresholds {
    critical              = 1
  }

  include_tags            = false
  notify_audit            = false

  require_full_window     = false
  
  notify_no_data          = true
  no_data_timeframe       = 10
  
  renotify_interval       = 0
}

# System: CPU running time
resource "datadog_monitor" "monitor_query_alert_system_cpu_usage" {
  type                = "query alert"
  name                = "System: CPU running time"  
  message             = "@slack-monitoring : CPU Running Alert\n\n\nHost: {{host.name}}\n\nPercent of time the CPU spent running the system: {{value}}\n\n"
  query               = "avg(last_1m):avg:system.cpu.system {project:${var.gcp-project-id}} by {host} > 90"
  monitor_thresholds {
    critical            = 90
  }

  include_tags          = false
  notify_audit          = false
  
  notify_no_data        = false
  renotify_interval     = 0

  require_full_window   = false

  new_group_delay       = 300
  escalation_message    = ""
}