class mysqllib {

  include mysql::client

  define mysqldb( $user, $password, $db = $name, $clienthost = 'localhost', $host = 'localhost', $privileges = 'ALL' ) {
    exec { "create-${db}-db-${clienthost}":
      unless => "/usr/bin/mysql -h${host} -uroot -e \"SHOW GRANTS FOR '${user}'@'${clienthost}';\" | grep 'ON `${db}`.*'",
      command => "/usr/bin/mysql -h${host} -uroot -e \"CREATE DATABASE IF NOT EXISTS ${db}; GRANT ${privileges} ON ${db}.* TO '${user}'@'${clienthost}' IDENTIFIED BY '${password}'; FLUSH PRIVILEGES;\"",
      require => Service["mysql"],
    }
  }

}
