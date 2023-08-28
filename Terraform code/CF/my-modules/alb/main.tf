resource "aws_lb_target_group" "my-target-group" {
  
     health_check {
        interval            = 10
        path                = "/"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
    }

    name        = "webserver-group"
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = "${var.vpc_id}"
}

#bind the web servers to the target group
resource "aws_lb_target_group_attachment" "websever-attachment" {
    count = length(var.target_instances)
    target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
    target_id        = "${var.target_instances[count.index]}"
    port             = 80
}

resource "aws_lb" "webserver-alb" {
    name     = "my-test-alb"
    internal = false

    security_groups = var.alb_sec_groups

    subnets = var.alb_subnets

    tags = {
        Name = "webserver_alb"
    }

    ip_address_type    = "ipv4"
    load_balancer_type = "application"
}

resource "aws_lb_listener" "webserver-alb-listner" {
    load_balancer_arn = "${aws_lb.webserver-alb.arn}"
    port              = 443
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
    }
}