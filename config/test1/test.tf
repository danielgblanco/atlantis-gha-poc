data "http" "example" {
  url = "https://checkpoint-api.hashicorp.com/v1/check/terraformtest"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}
