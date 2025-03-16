# aws-cost-report-lambda
Lambda to track resources cost based on tags


## Build Command

```bash
rm -fr build-output-dir &&  uv pip install --target build-output-dir . &&  cd build-output-dir && zip -r9 aws_cost_reporter_lambda.zip * && cd ..

```