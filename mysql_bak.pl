#!/usr/bin/perl -w

=pod 
mysqldump 备份多份数据库
先备份数据结构 再备份数据结构
支持排除某些表
备份完后删除一个礼拜前的备份数据
=cut 

use POSIX qw(strftime);

my $rs;
my $backup_path = "/data/backup/"; 
my $file_ext    = ".sql.gz";
my $log         = "/data/log/mysql/backup.log";

my @time     = localtime();
my $weektime = time() - 7 * 86400;
my @wtime    = localtime($weektime);
my $day      = $time[3];

my $today    = $time[5] + 1900 . sprintf( "%02d", $time[4] + 1 ) . $time[3];
# 一个礼拜前
my $weekday = $wtime[5] + 1900 . sprintf( "%02d", $wtime[4] + 1 ) . $wtime[3];
my $bak_time = strftime( "%H", localtime );

my $db_test_a    = "db_test_a";
my $bakup_file  = "$backup_path$db_test_a$today$bak_time$file_ext";
my $unlink_file = "$backup_path$db_test_a$weekday$bak_time$file_ext";

my $db_struct = "db_gameinfo-user-struct";

# 只备份gaminfo 和 userdb结构
$rs =
`/usr/bin/mysqldump --opt -d --single-transaction --master-data -B $db_test_a db_test_b | gzip -c > $backup_path$db_struct$file_ext`;

# 只备份test_a 数据 并排除表某些表 并删除一个礼拜之前数据
$rs =
`/usr/bin/mysqldump --opt -t --single-transaction --master-data -B $db_test_a --ignore-table=$db_test_a.t_gift_card --ignore-table=$db_test_a.t_tmp_recharge_return | gzip -c > $bakup_file`;

my $size = -s "$backup_path$db_test_a$file_ext";
if ( $size < 1048576 ) {
    addlog( "ERROR", "mysqldump failed: $rs $!" );
}
else {
    addlog( "INFO", "mysqldump finished:$db_test_a $size" );
    unlink($unlink_file);
}

my $db_test_b = "db_test_b";

# 只备份 test_b 数据 并排除表 t_log t_log_item等表.并删除一个礼拜之前数据
for ( my $i = 1 ; $i < 7 ; $i++ ) {

    $rs =
`/usr/bin/mysqldump --opt -t --single-transaction --master-data -B $db_test_b$i--ignore-table=$db_test_b$i.t_log  --ignore-table=$db_test_b$i.t_log_item | gzip -c > $backup_path$db_test_b$i-$today$bak_time$file_ext`;
    my $size = -s "$backup_path$db_test_b$i-$today$bak_time$file_ext";
    if ( $size < 1048576 ) {
        addlog( "ERROR", "mysqldump failed: $rs $!" );
    }
    else {
        addlog( "INFO", "mysqldump finished:$db_test_b$i $size" );
        print "\n $backup_path$db_test_b$i-$weekday$bak_time$file_ext";
        unlink("$backup_path$db_test_b$i-$weekday$bak_time$file_ext");
    }
}

sub addlog {
    my ( $type, $message ) = @_;
    my $time = strftime( "%Y-%m-%d %H:%M:%S", localtime );
    open FH, ">>$log" or die "Can not open logfile: $!";
    print FH "$time [$type] $message\n";
    close FH;
}
