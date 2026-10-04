package br.com.fiap.dimdim.controller;

import br.com.fiap.dimdim.model.Cliente;
import br.com.fiap.dimdim.model.Conta;
import br.com.fiap.dimdim.model.TipoConta;
import br.com.fiap.dimdim.repository.ClienteRepository;
import br.com.fiap.dimdim.repository.ContaRepository;
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
@RequestMapping("/contas")
public class ContaController {

    private final ContaRepository contaRepository;
    private final ClienteRepository clienteRepository;

    public ContaController(ContaRepository contaRepository, ClienteRepository clienteRepository) {
        this.contaRepository = contaRepository;
        this.clienteRepository = clienteRepository;
    }

    // READ - lista
    @GetMapping
    public String listar(Model model) {
        model.addAttribute("contas", contaRepository.findAllComCliente());
        return "contas/lista";
    }

    @GetMapping("/novo")
    public String novo(Model model) {
        prepararFormulario(model, new Conta(), null);
        return "contas/form";
    }

    // CREATE
    @PostMapping
    public String criar(@Valid @ModelAttribute("conta") Conta conta,
                        BindingResult erros,
                        @RequestParam(required = false) Long clienteId,
                        Model model,
                        RedirectAttributes redirect) {
        Cliente cliente = validarCliente(clienteId, model);
        if (conta.getNumero() != null && contaRepository.existsByNumero(conta.getNumero())) {
            erros.rejectValue("numero", "duplicado", "Já existe uma conta com esse número");
        }
        if (erros.hasErrors() || cliente == null) {
            prepararFormulario(model, conta, clienteId);
            return "contas/form";
        }
        conta.setCliente(cliente);
        contaRepository.save(conta);
        redirect.addFlashAttribute("msg", "Conta " + conta.getNumero() + " aberta para " + cliente.getNome() + ".");
        return "redirect:/contas";
    }

    @GetMapping("/{id}/editar")
    public String editar(@PathVariable Long id, Model model) {
        Conta conta = buscar(id);
        prepararFormulario(model, conta, conta.getCliente().getId());
        return "contas/form";
    }

    // UPDATE
    @PostMapping("/{id}")
    public String atualizar(@PathVariable Long id,
                            @Valid @ModelAttribute("conta") Conta form,
                            BindingResult erros,
                            @RequestParam(required = false) Long clienteId,
                            Model model,
                            RedirectAttributes redirect) {
        form.setId(id);
        Cliente cliente = validarCliente(clienteId, model);
        if (form.getNumero() != null && contaRepository.existsByNumeroAndIdNot(form.getNumero(), id)) {
            erros.rejectValue("numero", "duplicado", "Já existe outra conta com esse número");
        }
        if (erros.hasErrors() || cliente == null) {
            prepararFormulario(model, form, clienteId);
            return "contas/form";
        }
        Conta conta = buscar(id);
        conta.setNumero(form.getNumero());
        conta.setAgencia(form.getAgencia());
        conta.setTipo(form.getTipo());
        conta.setSaldo(form.getSaldo());
        conta.setCliente(cliente);
        contaRepository.save(conta);
        redirect.addFlashAttribute("msg", "Conta " + conta.getNumero() + " atualizada.");
        return "redirect:/contas";
    }

    // DELETE
    @PostMapping("/{id}/excluir")
    public String excluir(@PathVariable Long id, RedirectAttributes redirect) {
        Conta conta = buscar(id);
        contaRepository.deleteById(id);
        redirect.addFlashAttribute("msg", "Conta " + conta.getNumero() + " encerrada.");
        return "redirect:/contas";
    }

    private Cliente validarCliente(Long clienteId, Model model) {
        Cliente cliente = clienteId == null ? null : clienteRepository.findById(clienteId).orElse(null);
        if (cliente == null) {
            model.addAttribute("erroCliente", "Selecione o cliente dono da conta");
        }
        return cliente;
    }

    private void prepararFormulario(Model model, Conta conta, Long clienteSelecionado) {
        model.addAttribute("conta", conta);
        model.addAttribute("clientes", clienteRepository.findAll(Sort.by("nome")));
        model.addAttribute("tipos", TipoConta.values());
        model.addAttribute("clienteSelecionado", clienteSelecionado);
    }

    private Conta buscar(Long id) {
        return contaRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Conta não encontrada"));
    }
}
