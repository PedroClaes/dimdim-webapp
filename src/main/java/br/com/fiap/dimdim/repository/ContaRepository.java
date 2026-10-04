package br.com.fiap.dimdim.repository;

import br.com.fiap.dimdim.model.Conta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ContaRepository extends JpaRepository<Conta, Long> {

    // "join fetch" traz o cliente junto na mesma consulta (evita LazyInitializationException
    // na tela, já que o cliente é LAZY e open-in-view está desligado)
    @Query("select c from Conta c join fetch c.cliente order by c.cliente.nome, c.numero")
    List<Conta> findAllComCliente();

    boolean existsByNumero(String numero);
    boolean existsByNumeroAndIdNot(String numero, Long id);
}
