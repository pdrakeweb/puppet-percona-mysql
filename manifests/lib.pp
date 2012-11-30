class mysqllib {

  include mysql::client

  define mysqldb( $user, $password, $clienthost = 'localhost', $host = 'localhost' ) {
    exec { "create-${name}-db":
      unless => "/usr/bin/mysql -h${host} -u${user} -p${password} ${name}",
      command => "/usr/bin/mysql -h${host} -uroot -e \"create database if not exists ${name}; grant all on ${name}.* to '${user}'@'${clienthost}' identified by '${password}'; flush privileges;\"",
      require => Service["mysql"],
    }
  }

}
