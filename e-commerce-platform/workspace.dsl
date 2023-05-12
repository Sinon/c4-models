workspace "e-commerce company System Design exercise" "User birthday offers" {

    model {
        user = person "User" "A user of an e-commerce platform"

        eCommerce = softwaresystem "e-Commerce company" "e-Commerce platform" {
            webApplication = container "Web Application" "Allows users to buy from e-commerce site" "React, Javascript" {
                tags "Application"
            }
            userService = group "User Service" {
                userAPI = container "User Service API" "CRUD API for interacting with user data" "REST, FastAPI" {
                    tags "UserService" "Service API"
                    signinController = component "Sign In Controller" "Allows users to sign in to the e-commerce platform" "REST API"
                    userProfileController = component "UserProfile controller" "Interface for UserProfile" "REST API"
                    wishListController = component "UserWishlist controller" "Interface for UserWishList" "REST API"
                    userOfferController = component "UserOffer controller" "Interface for UserOffer" "REST API"
                }
                userDatabase = container "User Database" "Stores information regards the user" "Postgres, SQL" {
                    tags "UserService" "Database"
                }
                userAPI -> userDatabase "Reads from and writes to"
            }
            recommendationService = group "Recommendation Service" {
                recommendAPI = container "Recommendation Service API" "CRUD API for fetching item recommendations" "REST, FastAPI"{
                    tags "RecommendationService" "Service API"
                    userRecommendationController = component "User item recommendation controller" "API for fetch user item recommendations" "REST API"
                }
                graphDB = container "Graph DB" "Holds item relationship data" "Neo4j" {
                    tags "RecommendationService" "Database"
                }
                recommendAPI -> graphDB "Reads from and writes to"
            }

            fetcherLambda = container "Scheduled Birthday Fetcher lambda" "Scheduled Lambda for calculating users who should receive email" "Lambda, python"{
                tags "Amazon Web Services - Lambda Lambda Function"
            }

            emailLambda = container "Email Sender lambda" "Lambda for generating and sending email for single user" "Lambda, python"{
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
        webApplication -> userAPI "Login a given user and provider User Profile data"
        fetcherLambda -> userAPI "Fetches the users in birthday scope"
        fetcherLambda -> emailLambda "Triggers the birthday email lambda"
        emailLambda -> userAPI "Fetches the user profile & wishlist of the user."
        emailLambda -> stockApi "Fetches the stock levels "
        emailLambda -> recommendAPI "Fetches the recommended items for a user"
        emailLambda -> emailAPI "Sends email"

        # relationships to/from components
        webApplication -> signInController "Makes API call to" "JSON/HTTPS"
        webApplication -> userProfileController "Makes API call to" "JSON/HTTPS"
        webApplication -> userOfferController "Makes API call to" "JSON/HTTPS"

        fetcherLambda -> userProfileController "Makes API call to" "JSON/HTTPS"

        emailLambda -> wishListController "Makes API call to" "JSON/HTTPS"
        emailLambda -> userRecommendationController "Makes API call to" "JSON/HTTPS"
        emailLambda -> userOfferController "Makes API call to" "JSON/HTTPS"
        emailLambda -> userProfileController "Makes API call to" "JSON/HTTPS"

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

                    lambdas = deploymentNode "Lambdas" {
                        tags "Amazon Web Service - Lambda"
                        fetcherLambdaInstance = containerInstance fetcherLambda
                        emailLambdaInstance = containerInstance emailLambda
                    }

                    scaling = deploymentNode "Autoscaling group" {
                        tags "Amazon Web Services - Auto Scaling"

                        ec2 = deploymentNode "Amazon EC2" {
                            tags "Amazon Web Services - EC2"

                            webApplicationInstance = containerInstance webApplication
                        }
                        eks = deploymentNode "Amazon EKS" {
                            tags "Amazon Web Services - Elastic Kubernetes Service"

                            recommendationServiceInstance = containerInstance recommendAPI
                            userServiceInstance = containerInstance userAPI
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
                scaling userDatabaseInstance stockDatabaseInstance
                lambdas
            }
        }
        container eCommerce "eCommerceContainers" {
            include *
            autolayout lr
        }
        component userAPI "UserComponents" {
            include *
            autoLayout
            description "The component diagram for the User API."
        }
        component recommendAPI "RecommendComponents" {
            include *
            autoLayout
            description "The component diagram for the Recommendations API."
        }
        dynamic eCommerce "BirthdayFeature" "Summarise the flow of the birthday offer feature" {
            fetcherLambda -> userAPI "Fetch users whose birthday falls in specified time window - userProfileController"
            fetcherLambda -> emailLambda "Trigger email sending lambda for each user in scope"
            
            emailLambda -> userAPI "Fetch the users wishlist - wishListController"
            emailLambda -> recommendAPI "(Optional) Fetch the users item recommendations - userRecommendationController"
            emailLambda -> emailAPI "Populate email template and send to SES for delivery"
            emailLambda -> userAPI "Set Birthday email sent timestamp on users profile - userProfileController"
            emailLambda -> userAPI "Store the item offers presented in email - userOfferController"
            
            webApplication -> userAPI "User logs into platform during offer period - signinController"
            webApplication -> userAPI "User profile is fetched which indicates if offer banner should be displayed - userProfileController"
            webApplication -> userAPI "Fetch the active user offer for display - userOfferController"

            autoLayout
            description "Dynamic diagram describing the main flows for the birthday offer feature"
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
