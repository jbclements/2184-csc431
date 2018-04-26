class { 'java':
  distribution => 'jre',
}

package { "clang":
  ensure => 'installed',
}

package { "nasm":
  ensure => 'installed',
}

package { "python3.6":
  ensure => 'installed',
}

package { "nodejs":
  ensure => 'installed',
}
