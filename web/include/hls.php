<?php

function _hls_generate_extif($duration, $time, $path){
  if ( !strpos($duration,'.') ) {
    $duration .= ".00";
  }
  if ( !strpos($time,'.') ) {
    $time .= ".00";
  }
  echo "#EXTINF:".$duration.",\n";
  echo "http://$_SERVER[HTTP_HOST]".strtok($_SERVER["REQUEST_URI"],'?')."?action=stream_hls_video&path=".urlencode($path)."&time=".$time."\n";
}

function stream_hls_chunk($file,$time = "0.00",$subtitles=false) {

  global $config_array;

  $file = cleanpath($file);

  if ( !file_exists($file) ) {
    error_log("[Revoku] Could not access file \"$file\"!");
    return false;
  }

  $startfftime = gmdate("H:i:s",floatval($time));
  $lengthfftime = gmdate("H:i:s",floatval($config_array['stream']['chunk_duration']));

  # Convert Start to Float
  if ( strpos($startfftime,'.') ) {
    $startfftime .= '.00';
  }
  if ( strpos($lengthfftime,'.') ) {
    $lengthfftime .= '.00';
  }



  # Disable output bufferring
  ob_end_flush();

  header('Accept-Ranges: bytes');
  header('Last-Modified: '.gmdate('D, d M Y H:i:s', filemtime($file)));
  header('Content-type: video/mpegts');

  $additonalffmpeg = "";

  if ( $subtitles ) {
    # Check if the output has bitmap titles, If not? Disable trying as we don't need to do anything.
    exec($config_array['applications']['ffprobe']." -i \"$file\" -v quiet -show_entries stream -of csv=\"p=0\"",$ffprobeoutput);
    if ( stripos($ffprobeoutput, "dvdsub") ) {
      $additionalffmpeg = "-filter_complex \"[0:v][0:s:0]overlay[v]\" -map [v] -map 0:a";
    }
  }


  $command = $config_array['applications']['ffmpeg']." -noaccurate_seek -ss ".$startfftime." -i \"".$file."\" -force_key_frames \"expr:gte(t,n_forced*2)\" -t ".$lengthfftime." $additonalffmpeg -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a mp3 -ss 0 -b:v ".$config_array['stream']['video_bitrate']." -b:a ".$config_array['stream']['audio_bitrate']." -r 30 -f mpegts pipe:";
  error_log("[Revoku][Debug] Running External Command: '$command'");
  passthru($command,$return_var);

  if ( $return_var != 0 ) {
    error_log("[Revoku] Error running FFMPEG, Error code $return_var!");
    return false;
  }

  return true;
}

function stream_hls_m3u8($file) {

  global $config_array;

  $file = cleanpath($file);

  if ( !file_exists($file) ) {
    error_log("[Revoku] Could not access file \"$file\"!");
    return false;
  }

  # Pull in file info
  exec($config_array['applications']['ffprobe']." \"".$file."\" -show_entries format=duration -v quiet -of csv=\"p=0\"",$ffprobeoutput);

  # Shit bricks if we can't read the file
  if ( !isset($ffprobeoutput[0]) || $ffprobeoutput[0] == "" ) {
    error_log("[Revoku] Could not process file \"$file\" via ffprobe!");
    return false;
  }

  # Generate non-float file duration
  $fileduration = $ffprobeoutput[0];
  # Generate the number of segments we'll be using ( with remainder )
  $durationsegments = $fileduration / floatval($config_array['stream']['chunk_duration']);
  # Generate the number of whole segments we have available
  $totalwholefiles = preg_replace('/\.[0-9]+/', '', $durationsegments);
  # Generate the remaining time of the last frame in seconds if we have a remainder on the segmentation
#  $remainingframeseconds = preg_replace('/\.[0-9]+/', '', (($durationsegments - $totalwholefiles) * floatval($config_array['stream']['chunk_duration'])));
  $remainingframeseconds = round(($durationsegments - $totalwholefiles) * floatval($config_array['stream']['chunk_duration']),2,PHP_ROUND_HALF_DOWN);

  # Disable Output Buffering
  ob_end_flush();

  # Print Actual HTTP Header
  header("Content-Type: application/x-mpegurl");

  # Generate Header
  echo "#EXTM3U
#EXT-X-TARGETDURATION:".$config_array['stream']['chunk_duration']."
#EXT-X-VERSION:3
#EXT-X-ALLOW-CACHE:YES
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-MEDIA-SEQUENCE:1\n";

  # Generate Streaming List
  for ($segment = 0; $segment <= $totalwholefiles; $segment++) {
    _hls_generate_extif($config_array['stream']['chunk_duration'],($segment * $config_array['stream']['chunk_duration']),$file);
  }

  # Generate Remainder Streaming Item
  _hls_generate_extif($remainingframeseconds,(($totalwholefiles + 1) * $config_array['stream']['chunk_duration']),$file);

  # Generate End of List
  echo "#EXT-X-ENDLIST";

  return true;
}

function stream_hls_caption($file) {

  global $config_array;

  $file = cleanpath($file);

  if ( !file_exists($file) ) {
    error_log("[Revoku] Could not access file \"$file\"!");
    return false;
  }

  ob_end_flush();
  passthru($config_array['applications']['ffmpeg']." \"".$file."\" -vn -an -codec:s:0.1 srt pipe:");
  
  return true;
}
