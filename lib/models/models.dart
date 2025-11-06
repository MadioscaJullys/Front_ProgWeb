// Adapter Pattern: Os métodos fromJson e toJson adaptam os dados JSON da API para objetos Dart e vice-versa,
// permitindo que a aplicação trabalhe com objetos tipados em vez de mapas JSON crus.
// - fromJson: Converte Map<String, dynamic> (JSON) para objeto Dart tipado
// - toJson: Converte objeto Dart para Map<String, dynamic> (JSON serializável)
class User {
  final int id;  // ID único do usuário
  final String email;  // Email (único)
  final String? fullName;  // Nome completo (opcional)
  final String? profileImageUrl;  // URL da imagem de perfil
  final String? profileImageBase64;  // Imagem em base64
  final Role role;  // Role/perfil do usuário

  User({  // Construtor com parâmetros nomeados
    required this.id,  // ID obrigatório
    required this.email,  // Email obrigatório
    this.fullName,  // Nome opcional
    this.profileImageUrl,  // URL opcional
    this.profileImageBase64,  // Base64 opcional
    required this.role,  // Role obrigatório
  });

  // Adapter Pattern: Método factory que converte JSON da API para objeto User
  factory User.fromJson(Map<String, dynamic> json) {  // Recebe Map do JSON
    return User(  // Cria instância User com dados adaptados
      id: json['id'],  // Adapta campo 'id' do JSON
      email: json['email'],  // Adapta campo 'email'
      fullName: json['full_name'],  // Adapta campo 'full_name' (pode ser null)
      profileImageUrl: json['profile_image_url'],  // Adapta URL da imagem
      profileImageBase64: json['profile_image_base64'],  // Adapta base64
      role: Role.fromJson(json['role']),  // Adapta objeto Role aninhado
    );
  }

  // Adapter Pattern: Método que converte objeto User para JSON para envio à API
  Map<String, dynamic> toJson() {  // Retorna Map para serialização
    return {  // Cria Map com campos adaptados para JSON
      'id': id,  // Campo 'id' adaptado
      'email': email,  // Campo 'email' adaptado
      'full_name': fullName,  // Campo 'full_name' (pode ser null)
      'profile_image_url': profileImageUrl,  // URL adaptada
      'profile_image_base64': profileImageBase64,  // Base64 adaptada
      'role_id': role.id,  // Apenas ID do role (formato da API)
    };
  }
}

class UserCreate {
  final String email;  // Email do novo usuário
  final String password;  // Senha do novo usuário
  final String? fullName;  // Nome completo (opcional)
  final String? profileImageUrl;  // URL da imagem de perfil
  final String? profileImageBase64;  // Imagem em base64
  final int roleId;  // ID do role a ser atribuído

  UserCreate({  // Construtor para criação de usuário
    required this.email,  // Email obrigatório
    required this.password,  // Senha obrigatória
    this.fullName,  // Nome opcional
    this.profileImageUrl,  // URL opcional
    this.profileImageBase64,  // Base64 opcional
    required this.roleId,  // Role obrigatório
  });

  // Adapter Pattern: Converte UserCreate para JSON para envio à API
  Map<String, dynamic> toJson() {  // Retorna Map serializável
    return {  // Map com campos no formato esperado pela API
      'email': email,  // Campo 'email' adaptado
      'password': password,  // Campo 'password' adaptado
      'full_name': fullName,  // Campo 'full_name' (pode ser null)
      'profile_image_url': profileImageUrl,  // URL adaptada
      'profile_image_base64': profileImageBase64,  // Base64 adaptada
      'role_id': roleId,  // ID do role adaptado
    };
  }
}

class UserUpdate {
  final String? email;  // Email atualizado (opcional)
  final String? password;  // Senha atualizada (opcional)
  final String? fullName;  // Nome completo atualizado (opcional)
  final String? profileImageUrl;  // URL da imagem atualizada (opcional)
  final String? profileImageBase64;  // Imagem em base64 atualizada (opcional)
  final int? roleId;  // ID do role atualizado (opcional)

  UserUpdate({  // Construtor para atualização de usuário
    this.email,  // Todos os campos são opcionais
    this.password,
    this.fullName,
    this.profileImageUrl,
    this.profileImageBase64,
    this.roleId,
  });

  // Adapter Pattern: Converte UserUpdate para JSON para envio à API
  Map<String, dynamic> toJson() {  // Retorna Map serializável
    Map<String, dynamic> json = {};  // Map vazio inicialmente
    if (email != null) json['email'] = email;  // Adiciona apenas campos não-nulos
    if (password != null) json['password'] = password;
    if (fullName != null) json['full_name'] = fullName;
    if (profileImageUrl != null) json['profile_image_url'] = profileImageUrl;
    if (profileImageBase64 != null) json['profile_image_base64'] = profileImageBase64;
    if (roleId != null) json['role_id'] = roleId;
    return json;  // Retorna apenas campos que foram fornecidos
  }
}

class Role {
  final int id;  // ID único do role
  final String name;  // Nome do role (ex: 'admin', 'user')

  Role({required this.id, required this.name});  // Construtor com ID e nome obrigatórios

  // Adapter Pattern: Factory que converte JSON da API para objeto Role
  factory Role.fromJson(Map<String, dynamic> json) {  // Recebe Map do JSON da API
    return Role(  // Cria Role com dados adaptados
      id: json['id'],  // Adapta campo 'id' do JSON
      name: json['name'],  // Adapta campo 'name' do JSON
    );
  }

  // Adapter Pattern: Converte Role para JSON para envio à API
  Map<String, dynamic> toJson() {  // Retorna Map serializável
    return {  // Map com campos no formato esperado pela API
      'id': id,  // ID do role
      'name': name,  // Nome do role
    };
  }
}

class RoleCreate {
  final String name;  // Nome do novo role

  RoleCreate({required this.name});  // Construtor com nome obrigatório

  // Adapter Pattern: Converte RoleCreate para JSON para envio à API
  Map<String, dynamic> toJson() {  // Retorna Map serializável
    return {  // Map com campo no formato esperado pela API
      'name': name,  // Campo 'name' adaptado
    };
  }
}
