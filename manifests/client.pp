class mysql::client {

  include mysql

  package {
    "percona-server-client-5.5": 
      ensure  => latest,
      require => [ Package["mysql-client"], Package["percona-server-common-5.5"], Apt::Source["percona"] ];
    "libmysqlclient-dev":
      ensure => latest,
      require => Apt::Source["percona"];
    "mysql-client":
      ensure  => absent,
      require => Package["mysql-client-core-5.5"];
    "mysql-client-core-5.5":
      ensure  => absent;
  }

  if !defined(Package["mysql-server"]) {
    package { 
      "mysql-server":
        ensure  => absent,
        require => Package["mysql-server-core-5.5"];
      "mysql-server-core-5.5":
        ensure  => absent; 
    }
  }

}
