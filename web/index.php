<?php
namespace Web;

use Services\filesystem as filesystem;
use Services\hls_playback as hls_playback;
class main
{
    /**
     * main constructor.
     */
    public function __construct()
    {
        $this->configuration_path = dirname(__FILE__) . "/config.ini";
        $this->revokuversion = "2.0";
        $this->dirname = dirname(__FILE__);
    }

    public function index(filesystem $filesystem, hls_playback $hls_playback)
    {

        # Pull in Configuration
        if (!file_exists($this->configuration_path)) {
            error_log("[Revoku] Could not open configuration at \"$this->configuration_path\"");
            header("HTTP/1.0 500 Internal Server Error");
            exit(1);
        }

        $config_array = parse_ini_file($this->configuration_path, true);
        $config_array['revoku']['version'] = $this->revokuversion;

        # Parse Input
        if (!isset($_GET['action']) || $_GET['action'] == "") {
            error_log("[Revoku] No Action was supplied! Can't process.");
            header("HTTP/1.0 501 Not Implemented");
            exit(1);
        }

        switch ($_GET['action']) {
            case "serverinfo":
                serverinfo();
                break;
            case "stream_hls_m3u8":
                if (!$hls_playback->stream_hls_m3u8($filesystem,$_GET['path'])) {
                    error_log("[Revoku] Action stream_hls_m3u8 failed!");
                    header("HTTP/1.0 500 Internal Server Error");
                    exit(1);
                }
                break;
            case "stream_hls_video":
                if (!$hls_playback->stream_hls_chunk($_GET['path'], $_GET['time'])) {
                    error_log("[Revoku] Action stream_hls_video failed!");
                    header("HTTP/1.0 500 Internal Server Error");
                    exit(1);
                }
                break;
            case "pathlist":
                if (!$filesystem->pathlist($_GET['path'])) {
                    error_log("[Revoku] Action pathlist failed!");
                    header("HTTP/1.0 500 Internal Server Error");
                    exit(1);
                }
                break;
            case "fileinfo":
                if (!$filesystem->fileinfo($_GET['path'])) {
                    error_log("[Revoku] Action fileinfo failed!");
                    header("HTTP/1.0 500 Internal Server Error");
                    exit(1);
                }
                break;
            default:
                error_log("[Revoku] Unknown Action: " . $_GET['action']);
                header("HTTP/1.0 501 Not Implemented");
                exit(1);
        }
    }
}