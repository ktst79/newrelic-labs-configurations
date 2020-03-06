# Under construction...

This would include followings.
- Logs, Logs in Context
    - Containers Logs: Done
        - By using fluentd container and docker logging driver (fluentd)
    - Logs in Context: Done
        -  For web application (fluentd plugin deplyed as side car and monitor application log)
- Containers
    - On premise docker: Done
    - ECS on EC2 or Fargate
    - EKS on EC2 or Fargate
- Prerequisite
    - python-yq to parse yaml. Can be installed by pip install yq or brew install python-yq for mac.
    - Need to add pom dependency for logback new relic agent
