<?php

# Settings / Variables
$revokuversion = "2.0";
$configuration_path = dirname( __FILE__ )."/config.ini";

#### Starting Revoku ####
$realpath = dirname( __FILE__ );

include_once($realpath."/include/shared.php");
include_once($realpath."/include/db.php");
include_once($realpath."/include/filesystem.php");
include_once($realpath."/include/hls.php");
include_once($realpath."/include/serverinfo.php");
include_once($realpath."/include/user.php");
include_once($realpath."/include/ratings.php");

# Pull in Configuration
if ( !file_exists($configuration_path) ) {
  error_log("[Revoku] Could not open configuration at \"$configuration_path\"");
  header("HTTP/1.0 500 Internal Server Error");
  exit(1);
}

$config_array = parse_ini_file($configuration_path,true);
$config_array['revoku']['version'] = $revokuversion;

# Parse Input
if(!isset($_GET['action']) || $_GET['action'] == "" ) {
  error_log("[Revoku] No Action was supplied! Can't process.");
  header("HTTP/1.0 501 Not Implemented");
  exit(1);
}

switch($_GET['action']) {
  case "serverinfo":
    serverinfo();
    break;
  case "stream_hls_m3u8":
    if (!stream_hls_m3u8($_GET['path'])) {
      error_log("[Revoku] Action stream_hls_m3u8 failed!");
      header("HTTP/1.0 500 Internal Server Error");
      exit(1);
    }
    break;
  case "stream_hls_video":
    if (!stream_hls_chunk($_GET['path'],$_GET['time'])) {
      error_log("[Revoku] Action stream_hls_video failed!");
      header("HTTP/1.0 500 Internal Server Error");
      exit(1);
    }
    break;
  case "pathlist":
    if (!pathlist($_GET['path'])) {
      error_log("[Revoku] Action pathlist failed!");
      header("HTTP/1.0 500 Internal Server Error");
      exit(1);
    }
    break;
  case "fileinfo":
    if (!fileinfo($_GET['path'])) {
      error_log("[Revoku] Action fileinfo failed!");
      header("HTTP/1.0 500 Internal Server Error");
      exit(1);
    }
    break;
  default:
    error_log("[Revoku] Unknown Action: ".$_GET['action']);
    header("HTTP/1.0 501 Not Implemented");
    exit(1);
}
