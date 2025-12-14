import run
from apig_wsgi import make_lambda_handler

handler = make_lambda_handler(run.app, binary_support=True)