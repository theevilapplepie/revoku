<?php

function serverinfo() {
  global $config_array;

  if ( isset($config_array['revoku']['hostname']) && $config_array['revoku']['hostname'] != "" ) {
    $hosntame = $config_array['revoku']['hostname'];
  } else {
    $hostname = gethostname();
  }

  $returndata = Array (
    'servername' => $hostname,
    'version' => $config_array['revoku']['version'],
    'shares' => array_keys($config_array['paths']),
  );
  echo json_encode($returndata);
  return true;  
}
