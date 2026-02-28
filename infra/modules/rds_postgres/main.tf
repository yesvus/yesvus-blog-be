resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-pg"
  family = var.parameter_group_family

  parameter {
    name  = "client_encoding"
    value = "UTF8"
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-postgres"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  parameter_group_name    = aws_db_parameter_group.this.name
  vpc_security_group_ids  = [var.rds_security_group_id]
  publicly_accessible     = false
  multi_az                = false
  storage_encrypted       = true
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  tags = var.tags
}
