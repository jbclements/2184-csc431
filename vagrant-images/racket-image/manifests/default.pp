    include apt
    
    class { 'apt':
     always_apt_update => true,
    }
    
    apt::ppa { 'ppa:plt/racket':}
    
    package { "racket":
      ensure => 'installed',
      require => Apt::Ppa['ppa:plt/racket'],
    }

