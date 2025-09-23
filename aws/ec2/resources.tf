// Define the resources to create
// Provisions the following into AWS: 
//    EC2 Instance, S3 Bucket

// EC2 Instance
resource "aws_instance" "ec2" {
  instance_type = var.instance_type
  ami           = var.instance_ami
  count         = var.instance_count

  subnet_id = data.aws_subnet.selected.id
  tags = {
    name  = "ec2-${count.index}"
    owner = var.instance_owner
    ttl   = "-1"
  }
}

// S3 Bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket_prefix = var.bucket_name
  tags          = var.tags
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
