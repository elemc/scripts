#!/usr/bin/perl -s

use warnings;
use strict;

use File::Temp qw/ tempdir /;
use File::Spec::Functions;
use File::Copy;

our $MOUNT_POINT            = "/mnt/repos";
our $INCOMING_PACKAGES_DIR  = "$MOUNT_POINT/incoming-pkgs";
our $MOUNT_COMMAND          = "/usr/bin/sshfs root\@elemc.name:/srv/web/repos ${MOUNT_POINT} -o allow_other,uid=1000,gid=990 2>&1";
our $UMOUNT_COMMAND         = "/usr/bin/fusermount -u ${MOUNT_POINT}";
our $UPDATE_REPOS_CMD       = "ssh root\@elemc.name 'python /usr/local/bin/sortrpms.py'";

our %EXTERNAL_TOOLS         = ( 'mock'              => '/usr/bin/mock',
                                'fuse-sshfs'        => '/usr/bin/sshfs',
                                'fuse'              => '/usr/bin/fusermount',
                                'openssh-clients'   => '/usr/bin/ssh' );

our @SUPPORTED_FEDORA_VERS  = ( '19', '20', 'rawhide' );
our @SUPPORTED_EPEL_VERS    = ( '6' );
our @SUPPORTED_ARCHS        = ( 'i386', 'x86_64' );

our @packages_for_install;
our $build_result;

sub log_print {
    print "@_\n";
}

sub log_info {
    log_print( "\033[35m@_\033[0m" );
}

sub log_debug {
    log_print( "\033[36m@_\033[0m" );
}

sub check_make_dir {
    my $dir_name = "";
    if ( @_ == 0 ) {
        $dir_name = $MOUNT_POINT;
    }
    else {
        $dir_name = $_[0];
    }

    unless ( -d $dir_name ) {
        log_debug( "Try to make dir $dir_name" );
        mkdir $dir_name or return 0;
    }
    return 1;
}

sub check_external_tools {
    my $result = 1;    
    foreach my $tool_name ( keys %EXTERNAL_TOOLS ) {
        my $lresult = -x $EXTERNAL_TOOLS{$tool_name};
        push @packages_for_install, $tool_name unless $lresult;
        $result &&= $lresult; 
    }
    return $result;
}

sub check_pre_build {
    @_ == 2 or die "Missing parameters";
    my( $dist_name, $pkg_src_name )    = @_;
    return 0 unless ( $dist_name or $pkg_src_name );
    log_debug( "$dist_name", "$pkg_src_name" );
    
    return 0 unless check_external_tools();
    return 0 unless check_make_dir();
    

    return 1;
}

sub is_mounted {
    my $mount_point = $MOUNT_POINT;
    my $mount_result = `mount`;
    return 0 unless $mount_result =~ /$mount_point/;
    log_debug( "Result directory has mounted." );
    return 1;
}

sub mount {
    unless ( is_mounted ) {
        log_debug( "Try to mount $MOUNT_POINT" );
        my $mount_output = `$MOUNT_COMMAND`;
        my $mount_result = $?;
        if ( $mount_result == 0 ) {
            log_debug( "Mount successful.");
        }
        else {
            log_debug( $mount_output );
            die "Error in command $MOUNT_COMMAND";
        }
    }
    else {
        log_debug( "$MOUNT_POINT has mounted." );
    }
    return 1;
}

sub umount {
    if ( is_mounted ) {
        log_debug( "Try to umount $MOUNT_POINT" );
        my $umount_output = `$UMOUNT_COMMAND`;
        my $umount_result = $?;
        if ( $umount_result == 0 ) {
            log_debug( "Umount successful.");
        }
        else {
            log_debug( $umount_output );
            die "Error in command $UMOUNT_COMMAND";
        }
    }
    else {
        log_debug( "$MOUNT_POINT is not mounted." );
    }

    return 1;
}

sub usage {
    print "Please use this script as \n\t$0 [distributive] [/path/to/package.src.rpm]\n";
    print "\tdistributive is a 'fedora' or 'epel'\n";
    exit 1;
}

sub copy_packages {
    @_ == 1 or die "Missing parameter";

    my $result_dir = $_[0];
    # Copy packages from temporary dir to result
    opendir( TDIR, $result_dir ) or die "Can't open directory $result_dir: $!\n";
    my @all_files = readdir( TDIR );
    closedir( TDIR );

    foreach my $ft ( @all_files ) {
        my $full_path = catfile( $result_dir, $ft );
        next unless ( $full_path =~ /.rpm$/i );
        copy( $full_path, $INCOMING_PACKAGES_DIR ) or return 0;
    }

    return 1;
}

sub run_mock {
    @_ == 2 or die "Missing parameters";
    my $build_config = $_[0];
    my $source_package = $_[1];
    
    my $result_dir = tempdir( "/tmp/$build_config-XXXXXX", CLEANUP => 1 );
    log_info( "Build for $build_config in resultdir: $result_dir" );
    my $mock_cmd = "/usr/bin/mock -r $build_config --rebuild $source_package --resultdir $result_dir 2>&1";
    
    my $mock_output = `$mock_cmd`;
    my $mock_result = $?;
    if ( $mock_result == 0 ) {
        log_info( "Build finished." );
    }
    else {
        log_debug( $mock_output );
        die "Error in command \"$mock_cmd\".";
    }

    copy_packages( $result_dir );
}

sub build {
    @_ == 2 or die "Missing parameters";

    $build_result = 1;
    my $build_prefix = $_[0];
    my $pkg_src_name = $_[1];

    foreach my $arch (@SUPPORTED_ARCHS) {
        my $build_config = "$build_prefix-$arch";
        log_debug("Build begin $build_config");
        $build_result &&= run_mock( $build_config, $pkg_src_name );
        log_debug("Build end $build_config");
    }
}

sub main {
    if ( $#ARGV == -1 ) {
        usage()
    }
    elsif ( $#ARGV == 0 and $ARGV[0] =~ /setup/i ) {
        log_info( "Setup...\n\n" ); #TODO: make setup
        return 0;
    }

    my $dist_name      = $ARGV[0];
    my $pkg_src_name   = $ARGV[1];

    unless ( check_pre_build($dist_name, $pkg_src_name) ) {
        log_info( "Please install packages: @packages_for_install" );
        return 1;
    }

    mount();
    return 1 unless check_make_dir( $INCOMING_PACKAGES_DIR );
    log_info( "Build..." );

    my $build_prefix = "elemc-$dist_name";
    my @versions;
    if ( $dist_name =~ /fedora/i ) {
        @versions = @SUPPORTED_FEDORA_VERS;
    }
    else {
        @versions = @SUPPORTED_EPEL_VERS;
    }

    if ( $dist_name =~ /-/ ) {
        build( $build_prefix, $pkg_src_name );
    }
    else {
        foreach my $ver (@versions) {
            build( "${build_prefix}-${ver}", $pkg_src_name );
        }
    }
    
    umount();

    if ( $build_result ) {
        log_info( "Update repositories." );
        my $uc_output = `$UPDATE_REPOS_CMD`;
        my $uc_result = $?;

        if ( $uc_result != 0 ) {
            log_debug("Error in command $UPDATE_REPOS_CMD: $uc_output");
            return $uc_result;
        }
    }

    log_info("Final.");

    return 0;
}

exit main();
