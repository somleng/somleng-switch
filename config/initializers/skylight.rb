if Adhearsion.environment == :production
  Skylight.start!(
    file: File.join(__dir__, "../skylight.yml"),
    env: :production
  )
end
