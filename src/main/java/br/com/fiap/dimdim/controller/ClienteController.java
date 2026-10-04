package br.com.fiap.dimdim.controller;

import br.com.fiap.dimdim.model.Cliente;
import br.com.fiap.dimdim.repository.ClienteRepository;
import jakarta.validation.Valid;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/clientes")
public class ClienteController {

    private final ClienteRepository clienteRepository;

    public ClienteController(ClienteRepository clienteRepository) {
        this.clienteRepository = clienteRepository;
    }

    // READ - lista
    @GetMapping
    public String listar(Model model) {
        model.addAttribute("clientes", clienteRepository.findAll(Sort.by("nome")));
        return "clientes/lista";
    }

    @GetMapping("/novo")
    public String novo(Model model) {
        model.addAttribute("cliente", new Cliente());
        return "clientes/form";
    }

    // CREATE
    @PostMapping
    public String criar(@Valid @ModelAttribute("cliente") Cliente cliente,
                        BindingResult erros,
                        RedirectAttributes redirect) {
        if (cliente.getCpf() != null && clienteRepository.existsByCpf(cliente.getCpf())) {
            erros.rejectValue("cpf", "duplicado", "Já existe um cliente com esse CPF");
        }
        if (erros.hasErrors()) {
            return "clientes/form";
        }
        clienteRepository.save(cliente);
        redirect.addFlashAttribute("msg", "Cliente " + cliente.getNome() + " cadastrado.");
        return "redirect:/clientes";
    }

    @GetMapping("/{id}/editar")
    public String editar(@PathVariable Long id, Model model) {
        model.addAttribute("cliente", buscar(id));
        return "clientes/form";
    }

    // UPDATE
    @PostMapping("/{id}")
    public String atualizar(@PathVariable Long id,
                            @Valid @ModelAttribute("cliente") Cliente form,
                            BindingResult erros,
                            RedirectAttributes redirect) {
        form.setId(id);
        if (form.getCpf() != null && clienteRepository.existsByCpfAndIdNot(form.getCpf(), id)) {
            erros.rejectValue("cpf", "duplicado", "Já existe outro cliente com esse CPF");
        }
        if (erros.hasErrors()) {
            return "clientes/form";
        }
        // Carrega o registro do banco e altera só os campos do formulário,
        // assim a data de cadastro original é preservada
        Cliente cliente = buscar(id);
        cliente.setNome(form.getNome());
        cliente.setCpf(form.getCpf());
        cliente.setEmail(form.getEmail());
        clienteRepository.save(cliente);
        redirect.addFlashAttribute("msg", "Cliente " + cliente.getNome() + " atualizado.");
        return "redirect:/clientes";
    }

    // DELETE (as contas do cliente são excluídas junto, pelo cascade da entidade)
    @PostMapping("/{id}/excluir")
    public String excluir(@PathVariable Long id, RedirectAttributes redirect) {
        Cliente cliente = buscar(id);
        clienteRepository.deleteById(id);
        redirect.addFlashAttribute("msg",
                "Cliente " + cliente.getNome() + " e as contas dele foram excluídos.");
        return "redirect:/clientes";
    }

    private Cliente buscar(Long id) {
        return clienteRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Cliente não encontrado"));
    }
}
