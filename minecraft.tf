# We need to publish our SSH key so that we can use it when creating the instance
resource "digitalocean_ssh_key" "default" {
  name       = "SSH Key"
  public_key = file(var.pub_key)
}

resource "digitalocean_volume" "data" {
  region =  var.do_default_region
  name = "volume-sgp1-01"
  size = 1
  initial_filesystem_type = "ext4"
  lifecycle {
    prevent_destroy = false
  }
}

# Create a new Minecraft droplet
resource "digitalocean_droplet" "minecraft" {
  image    = var.do_image_name
  name     = "minecraft"
  region   = var.do_default_region
  size     = var.do_default_size
  ssh_keys = [digitalocean_ssh_key.default.id]
  volume_ids = [digitalocean_volume.data.id]    

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /mnt/volume_sgp1_01",
      "mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_volume-sgp1-01 /mnt/volume_sgp1_01",
      "echo '/dev/disk/by-id/scsi-0DO_Volume_volume-sgp1-01 /mnt/volume_sgp1_01  ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab",
    ] 
  }

  # provisioner "file" {
  #   source      = "data"
  #   destination = "/mnt/volume_sgp1_01"
  # }

  # SSH into it and download
  provisioner "remote-exec" {
    inline = [
      "docker pull itzg/minecraft-server:20190824",
      "docker run -d -it -e EULA=TRUE -v /mnt/volume_sgp1_01:/data -p 25565:25565 --name mc itzg/minecraft-server:20190824"
    ] 
  }
}

output "host" {
  value = digitalocean_droplet.minecraft.ipv4_address
}
resource "digitalocean_floating_ip" "minecraftip" {
  droplet_id = digitalocean_droplet.minecraft.id
  region = digitalocean_droplet.minecraft.region
}

output "fip" {
  value = digitalocean_floating_ip.minecraftip.ip_address
}

