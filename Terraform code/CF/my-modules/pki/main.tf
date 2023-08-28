#Generates a new public/private key pair used for accessing Ec2 instances after creation
#Private key will be saved locally and should be secured post creation


# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# Create the Key Pair
resource "aws_key_pair" "this" {
    key_name   = "ec2-key-pair"  
    public_key = tls_private_key.key_pair.public_key_openssh
    provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
        command = "echo '${tls_private_key.key_pair.private_key_pem}' > ../myKey.pem"
  }
}

