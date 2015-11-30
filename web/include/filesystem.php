<?php

function cleanpath($path) {

  global $config_array;

  # Determine if we're using a shortpath
  if ( preg_match('/^[^\/\\\]+/',$path,$matches) ) {
    $grepreturn = preg_grep('/^'.$matches[0].'$/i', array_keys($config_array['paths']));
    if ( count($grepreturn) < 1 ) {
      error_log("[Revoku] Attempted to lookup ShortPath \"".$matches[0]."\", Could not find!");
      return false;
    }
    $matchpath = array_shift($grepreturn);
    $path = preg_replace('/^[^\/\\\]+/',$config_array['paths'][$matchpath],$path);
  }

  # Does the file/dir exist?
  if ( !file_exists($path) ) {
    error_log("[Revoku] Attempted to return Path \"$path\", However path was invalid!");
    return false;
  }

  # Determine if we're in a defined path ( eg: don't go outside of it )
  $foundpath = false;
  foreach ($config_array['paths'] as $key => $value) {
    if ( preg_match('/^'.preg_quote($value,'/').'/i', realpath($path)) ) { 
      $foundpath = true;
      break;
    }
  }
  if ( !$foundpath ) {
    error_log("[Revoku] Path \"$path\" attempted outside of exported paths!");
    return false;
  }

  return $path;
}

function pathList($path) {

  $currentpath = cleanpath($path);
  if ( $currentpath === false ) { 
    error_log("[Revoku] pathList called and cleanpath returned false on input data");
    return false;
  }

  if ( !is_dir($currentpath) ) {
    error_log("[Revoku] pathList called with filename instead of directory!");
    return false;
  }

  $directorylist = scandir($currentpath);

  $returnlist = array();

  foreach ($directorylist as $entry) {
    # Skip dotfiles
    if ( preg_match('/^\./',$entry) ){
      continue;
    }

    $full = $currentpath."/".$entry;
    $pathinfo = pathinfo($entry);

    $title = $pathinfo['filename'];
    $title = str_replace("_"," ",$title);

    if ( $title == "" || is_null($title) ) {
      $title = $entry;
    }

    if ( is_dir($full) ) {
      $returnlist[] = array( 'type' => 'directory', 'Url' => $entry, 'Title' => $title );
      continue;
    } 
    if ( !is_file($full) ) {
      continue;
    }

    if ( !isset($pathinfo['extension']) || $pathinfo['extension'] == "" ) {
      continue;
    }

    if ( preg_match('/\.(avi|wmv|mkv|mov|mpeg|mpg|m4v|flv|3gp|m4v|mp4)$/i', $entry) ) {
      $type = "video";
    } elseif ( preg_match('/\.(wav|aiff|au|cdda|flac|m4a|wma|mp3|mp2|wma|aac|adf)$/i',	$entry) ) {
      $type = "audio";
    } else {
      $type = "file";
    }

    $returnlist[] = array( 'type' => $type, 'Url' => $entry, 'Title' => $title);

  }

  echo json_encode($returnlist);
  return true;
}

function videoinfo($file) {
  $pathinfo = pathinfo($file);
  $title = $pathinfo['filename'];
  $title = str_replace("_"," ",$title);
  $return['Title'] = $title;
  echo json_encode($return);
  return true;
}

function audioinfo($file) {
  global $config_array;

  $currentpath = cleanpath($file);
  if ( $currentpath === false ) {
    error_log("[Revoku] pathList called and cleanpath returned false on input data");
    return false;
  }
  $pathinfo = pathinfo($currentpath);
  $title = $pathinfo['filename'];
  $title = str_replace("_"," ",$title);

  # Setup our Return Data
  $returndata;
  $returndata['Title'] = $title;

  # We've got our basics, Lets get as much ID3 info as we can :)
  exec($config_array['applications']['ffprobe']." -i \"$currentpath\" -v quiet -show_entries format -of csv=\"p=0\":\"nk=0\":\"s=|\"",$ffprobeoutput);
  # Parse Data
  $dataarray = explode("|",$ffprobeoutput[0]);
  $filedata;
  foreach($dataarray as $value) {
    $data = explode("=", $value, 2);
    $filedata[$data[0]] = $data[1];
  }

  # Lets start assignments
  $assignments = Array(
    'duration' => 'Length',
    'probe_score' => 'UserStarRating',
    'tag:title' => 'Title',
    'tag:genre' => 'Categories',
    'tag:album' => 'Album',
    'tag:album_artist' => 'Artist',
    'tag:artist' => 'Artist',
  );

  foreach ( $assignments as $fflabel => $destlabel ) {
    if ( isset($filedata[$fflabel]) && $filedata[$fflabel] ) {
      $returndata[$destlabel] = $filedata[$fflabel];
    }
  }

  echo json_encode($returndata);

  return true;
}
