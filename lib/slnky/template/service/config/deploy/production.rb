set :stage, :production
server ENV['DEPLOY_PROD_SERVER'], user: ENV['DEPLOY_PROD_USER'], roles: %w{web app}
