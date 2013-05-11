# Put your servers here (you can put multiple servers: ex. "server1", "server2", "server3"...)
role :chef, "localhost"

# authentication info (example)
set :user, 'vagrant'
set :password, 'vagrant'
ssh_options[:port] = "2222"
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/your_key_for_auth.pem"]
