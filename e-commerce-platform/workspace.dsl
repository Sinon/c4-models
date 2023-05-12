workspace "e-commerce company System Design exercise" "User birthday offers" {

    model {
        user = person "User" "A user of an e-commerce platform"

        eCommerce = softwaresystem "e-Commerce company" "e-Commerce platform" {
            webApplication = container "Web Application" "Allows users to buy from e-commerce site" "React, Javascript" {
                tags "Application"
            }
            userService = group "User Service" {
                userApi = container "User Service API" "CRUD API for interacting with user data" "REST, FastAPI" {
                    tags "UserService" "Service API"
                    signinController = component "Sign In Controller" "Allows users to sign in to the e-commerce platform" "REST API"
                    userProfileController = component "UserProfile controller" "Interface for UserProfile" "REST API"
                    wishListController = component "UserWishlist controller" "Interface for UserWishList" "REST API"
                }
                userDatabase = container "User Database" "Stores information regards the user" "Postgres, SQL" {
                    tags "UserService" "Database"
                }
                userApi -> userDatabase "Reads from and writes to"
            }
            recommendationService = group "Recommendation Service" {
                recommendApi = container "Recommendation Service API" "CRUD API for fetching item recommendations" "REST, FastAPI"{
                    tags "RecommendationService" "Service API"
                    userRecommendationController = component "User item recommendation controller" "API for fetch user item recommendations" "REST API"
                }
                graphDB = container "Graph DB" "Holds item relationship data" "Neo4j" {
                    tags "RecommendationService" "Database"
                }
                recommendAPI -> graphDB "Reads from and writes to"
            }

            fetcherLambda = container "Birthday Fetcher lambda" "Scheduled Lambda for calculating users who should receive email" "Lambda, python"{
                tags "Amazon Web Services - Lambda Lambda Function"
            }

            emailLambda = container "Email sender lambda" "Lambda for generating and sending email for single user" "Lambda, python"{
                tags "Amazon Web Services - Lambda Lambda Function"
            }
            emailAPI = container "SES" "Simple Email Service" "SES, Email"{
                tags "Amazon Web Services - Simple Email Service SES"
            }

            stockService = group "Stock Service" {
                stockApi = container "Stock API" "CRUD API to interact with Item stock levels" "REST, FastAPI"{
                    tags "Stock" "Service API"
                }
                stockDatabase = container "Stock Database" "Stock DB" "Postgres, SQL"{
                    tags "Service 2" "Database"
                }
                stockApi -> stockDatabase "Reads from and writes to"
            }

        }
        # relationships between users and software systems
        user -> eCommerce "Uses"

        # relationships to/from containers
        webApplication -> userApi "Login a given user and provider User Profile data"
        fetcherLambda -> userApi "Fetches the users in birthday scope"
        fetcherLambda -> emailLambda "Triggers the birthday email lambda"
        emailLambda -> userApi "Fetches the user profile & wishlist of the user."
        emailLambda -> stockApi "Fetches the stock levels "
        emailLambda -> recommendAPI "Fetches the recommended items for a user"
        emailLambda -> emailAPI "Sends email"

        # relationships to/from components
        webApplication -> signInController "Makes API call to" "JSON/HTTPS"
        webApplication -> userProfileController "Makes API call to" "JSON/HTTPS"

        fetcherLambda -> userProfileController "Makes API call to" "JSON/HTTPS"

        emailLambda -> wishListController "Makes API call to" "JSON/HTTPS"
        emailLambda -> userRecommendationController "Makes API call to" "JSON/HTTPS"

        live = deploymentEnvironment "Live" {

            deploymentNode "Amazon Web Services" {
                tags "Amazon Web Services - Cloud"

                region = deploymentNode "US-East-1" {
                    tags "Amazon Web Services - Region"

                    route53 = infrastructureNode "Route 53" {
                        description "Highly available and scalable cloud DNS service."
                        tags "Amazon Web Services - Route 53"
                    }

                    elb = infrastructureNode "Elastic Load Balancer" {
                        description "Automatically distributes incoming application traffic."
                        tags "Amazon Web Services - Elastic Load Balancing"
                    }

                    deploymentNode "Lambdas" {
                        tags "Amazon Web Service - Lambda"
                        fetcherLambdaInstance = containerInstance fetcherLambda
                        emailLambdaInstance = containerInstance emailLambda
                    }

                    deploymentNode "Autoscaling group" {
                        tags "Amazon Web Services - Auto Scaling"

                        deploymentNode "Amazon EC2" {
                            tags "Amazon Web Services - EC2"

                            webApplicationInstance = containerInstance webApplication
                        }
                        deploymentNode "Amazon EKS" {
                            tags "Amazon Web Services - Elastic Kubernetes Service"

                            recommendationServiceInstance = containerInstance recommendApi
                            userServiceInstance = containerInstance userApi
                            stockServiceInstance = containerInstance stockApi
                        }
                    }

                    deploymentNode "Amazon RDS" {
                        tags "Amazon Web Services - RDS"

                        deploymentNode "Postgres" {
                            tags "Amazon Web Services - RDS Postgres instance"

                            userDatabaseInstance = containerInstance userDatabase
                            stockDatabaseInstance = containerInstance stockDatabase
                        }
                    }

                }
            }

            route53 -> elb "Forwards requests to" "HTTPS"
            elb -> webApplicationInstance "Forwards requests to" "HTTPS"
        }


    }

    views {
        deployment eCommerce "Live" "AmazonWebServicesDeployment" {
            include *
            autolayout lr

            animation {
                route53
                elb
                userDatabaseInstance
                stockDatabaseInstance
            }
        }
        systemContext eCommerce "eCommerceSystemContext" {
            include *
            autolayout lr
        }

        container eCommerce "eCommerceContainers" {
            include *
            autolayout lr
        }
        component userApi "UserComponents" {
            include *
            autoLayout
            description "The component diagram for the User API."
        }
        component recommendApi "RecommendComponents" {
            include *
            autoLayout
            description "The component diagram for the Recommendations API."
        }
        styles {
            element "Person" {
                color #08427b
                fontSize 22
                shape Person
            }
            element "Element" {
                shape roundedbox
                background #ffffff
            }
            element "Container" {
                background #ffffff
            }
            element "Application" {
                background #ffffff
            }
            element "Database" {
                shape cylinder
            }
        }

        themes https://static.structurizr.com/themes/amazon-web-services-2020.04.30/theme.json
    }

}
