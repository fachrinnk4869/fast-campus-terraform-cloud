terraform {
    backend "s3" {
        bucket         = "practice-remote-states-2"
        key            = "staging/ec2"
        region         = "us-east-1"
        encrypt        = true
    }
}