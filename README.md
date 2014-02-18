### Ridoku Cookbooks for OpsWorks.

# Special Variables

## Delayed Job

|Variable|Description|
|work_from_app_server|Run DJ Server on Application Server? true if worker is desired on App server.  false indicates you have a separate application Server.|
|workers|Object containing worker classes and queues|

```ruby
  # Single process monitoring DelayedJob queues: mail and dedupe
  deploy['workers']['delayed_job'] = ['mail,dedupe']

  # 2 processes, 1 monitoring mailer-queue, the other deduplication-queue
  deploy['workers']['sneakers'] = ['mailer-queue','deduplication-queue']
```
