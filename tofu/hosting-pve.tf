module "hosting-pve" {
  source = "./hosting-pve"
  tenants = [
    # {
    #   name = "lilly"
    #   id   = 10
    # },
    {
      name = "bene"
      id   = 11
      vms = [ 108 ]
    },
    {
      name = "timon"
      id   = 14
      vms = [ 109 ]
    },
    {
      name = "isa"
      id   = 15
      vms = [ 110 ]
    },
    {
      name = "noah"
      id   = 16
      vms = [ 111 ]
    },
    {
      name = "fux"
      id   = 17
      vms = [ 112 ]
    },
    {
      name = "freddy"
      id   = 18
      vms = [ 113 ]
    }
  ]
}
