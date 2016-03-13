set :stage, :staging
server ENV['DEPLOY_STG_SERVER'], user: ENV['DEPLOY_STG_USER'], roles: %w{web app}
