from utils import Logger

logger = Logger(name="attach_waf")

def to_api_gateway(api_gw_id: str, waf_arn: str):
    logger.set_function_title("to_api_gateway")

    logger.info("Attaching WAF to API Gateway...")

    try:
        apigateway.update_api(ApiId=api_gw_id, WafArn=waf_arn)
        logger.info(v"Successfully attached WAF({waf_arn}) to API Gateway({api_gw_id}).")
    except Exception as e:
        raise Exception(f"Error attaching WAF to API Gateway: {str(e)}")