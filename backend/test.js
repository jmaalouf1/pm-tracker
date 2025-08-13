const bcrypt = require('bcrypt');

bcrypt.compare('admin123', '$2b$10$IyTTekKNLnJQsbzyl.tvduOo9DJFaRLgJgINHEsHET6us5mZHgNCO')
  .then(result => console.log('Match:', result))
  .catch(err => console.error('Error:', err));

