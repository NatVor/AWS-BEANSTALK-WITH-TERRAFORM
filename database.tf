resource "aws_db_subnet_group" "teachua_app_db_subnet_group" {
  name       = "teachua-sg"
  subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]
  tags = {
    Name = "RDS Subnet Group"
  }

}

resource "aws_db_parameter_group" "teachua_param_group" {
  name   = "teachua-param-group"
  family = "mariadb10.5"  

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "collation_server"
    value = "utf8_bin"
  }
}

resource "aws_db_instance" "teachua_rds" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mariadb"
  engine_version         = "10.5"
  instance_class         = "db.t3.micro"
  identifier             = "teachua-db"
  db_name                = "teachua"
  username               = "user"
  password               = "password"
  # parameter_group_name   = "default.mariadb10.5"
  multi_az               = false
  publicly_accessible    = true
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.teachua_app_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.teachua_app_rds_sg.id]
  parameter_group_name   = aws_db_parameter_group.teachua_param_group.name
}

resource "null_resource" "grant_privileges" {
  depends_on = [aws_db_instance.teachua_rds]

   provisioner "local-exec" {
    command = <<EOT
    
    # until mysql -h ${aws_db_instance.teachua_rds.endpoint} -u user -ppassword -e "SELECT 1"; do
    #  echo "Waiting for RDS to be available..."
    #  sleep 60
    # done
    # mysql -h ${aws_db_instance.teachua_rds.endpoint} -u user -ppassword -e "GRANT ALL PRIVILEGES ON teachua.* TO 'user'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    # EOT

    until mysql -h teachua-db.ctegro5wnfvo.us-east-1.rds.amazonaws.com -P 3306 -u user -ppassword -e "SELECT 1"; do
      echo "Waiting for RDS to be available..."
      sleep 60
    done

    mysql -h teachua-db.ctegro5wnfvo.us-east-1.rds.amazonaws.com -P 3306 -u user -ppassword -e "GRANT ALL PRIVILEGES ON teachua.* TO 'user'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    EOT
  }
}