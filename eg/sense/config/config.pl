+{
    host => 'http://localhost:5001',
    salt => '39ikff0okvvi38ugd01',
    connect_info => {
        dsn => 'dbi:mysql:sense:lovevoice.local:3306',
        user => 'senses', 
        password => '6Pdl%9X]', 
        connect_options => {
            mysql_enable_utf8 => 1,
            RaiseError => 1,
            AutoCommit => 1,
            PrintError => 0,
        }
    },
};
