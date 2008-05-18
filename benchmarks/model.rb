# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner, Matt Smith
#

class Account
  def initialize(status, title, account_id)
    @status = status
    @title = title
    @account_id = account_id
  end
  
  attr :status, true
  attr :title, true
  attr :account_id, true
end

class Address
  def initialize(addr_id, city, state, zip)
    @addr_id = addr_id
    @city = city
    @state = state
    @zip = zip
  end
  
  attr :addr_id, true
  attr :city, true
  attr :state, true
  attr :zip, true
end