; extends

; Unquoted mapping keys are plain scalars and have no highlight capture
; upstream. Give them one so YAML keys can be themed like quoted keys.
((block_mapping_pair
   key: (flow_node
     (plain_scalar) @property.yaml))
  (#set! priority 105))
