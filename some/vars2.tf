# This matches var name and fails
variable vault_secret_id  {}

# This matches var name and it's OK
variable "vault_role_id"  {
    # some
    /* 
    something
    more
    */
    type        = string
    ephemeral   =  true
    sensitive   =  true
    /* ss
    something
    more
    */
}

# This doesn't match pattern name var
variable vault_some_var  {
    # some
    /* 
    something
    more
    */
    type        = string
    ephemeral   =  true
    sensitive   =  false
    /* ss
    something
    more
    */
}