# This matches var name nad it's OK
variable vault_secret_id  {
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

# This matches var name and fails
variable "vault_role_id"  {
    # some
    /* 
    something
    more
    */
    type        = string
    #ephemeral  = true
    ephemeral   =  false
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