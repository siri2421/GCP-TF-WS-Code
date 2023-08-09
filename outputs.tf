
 # For Outputs section
output "vm_name" {
  description = "The www VM 1 name."
  #value       = google_compute_instance.my_www_vm_1.name
  #value       = google_compute_instance.my_www_vms.*.name ### splat expression to iterate over all elements of the list
  value       = ({
    for _,vm in google_compute_instance.my_www_vms
    : vm.name => vm.network_interface[0].network_ip
  })
}


/*
output "www_instance_id" {
    value = google_compute_instance.my_www_vm_1.instance_id
}

output "www_instance_ip_addr" {
    value = google_compute_instance.my_www_vm_1.network_interface.0.network_ip

}
*/