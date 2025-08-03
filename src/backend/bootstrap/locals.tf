locals {
    bucket_size_bytes = var.tf_state_bucket.size_gb * 1024 * 1024 * 1024
}