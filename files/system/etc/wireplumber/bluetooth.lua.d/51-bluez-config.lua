-- Otimizações para dispositivos Bluetooth no WirePlumber (Fedora/Kinoite)
-- Previne que a qualidade de áudio caia para "Mono/Telefone" quando apps acessam o mic

bluez_monitor.properties = {
  -- Desativa a troca automática de perfil. O áudio permanece em Alta Qualidade (A2DP)
  -- mesmo se um app tentar acessar o mic. O mic só será ativado se você forçar.
  ["bluez5.autoswitch-profile"] = false,
  
  -- Força o uso de codecs de alta qualidade se o adaptador suportar
  ["bluez5.codecs"] = "[ sbc sbc_xq aac ]",
  
  -- Aumenta o buffer para evitar stuttering em fones chineses com chips genéricos
  ["bluez5.default-volume"] = 1.0,
}

-- Ajuste de latência para periféricos de áudio
bluez_monitor.rules = {
  {
    matches = {
      {
        { "device.name", "matches", "bluez_card.*" },
      },
    },
    apply_properties = {
      -- Aumenta um pouco o quantum para evitar cortes no Baseus EP10
      ["node.pause-on-idle"] = false,
    },
  },
}
